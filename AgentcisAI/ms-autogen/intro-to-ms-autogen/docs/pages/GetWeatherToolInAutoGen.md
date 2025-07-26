## 🌤️ Entity Extraction with Agentic Weather Retrieval in AutoGen 0.4+
We've all seen how powerful agents can be when orchestrated with purpose. Now let's extend their capabilities by registering [Tools](https://microsoft.github.io/autogen/stable/reference/python/autogen_core.tools.html#autogen_core.tools.FunctionTool), giving agents a way to interact with the real world.

First, let’s define what tools are in the world of Microsoft AutoGen.

🛠️ In AutoGen, tools are callable Python functions, wrapped in a way that allows agents to understand their purpose, parameters, and outputs. Think of them as skill modules: when an agent hits a challenge it can't answer with reasoning alone, it can invoke a tool to fetch, compute, or transform real-world data.

They’re registered using [FunctionTool](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/agents.html#function-tool), which automatically gives the tool an OpenAPI-like schema. This means agents can ask smart questions like: "Is there a tool that gets weather data?" …and AutoGen will know exactly what’s available, how to use it, and when it makes sense.

📌 **Use tools when:**
- Your agent needs access to external logic or APIs (e.g. weather data, file lookup, math computation).
- You're designing a modular workflow that separates what agents do from how things get done.
- You want reproducibility and clarity—tools are defined once, discoverable by name, and invocable by design.

They’re the backbone of smart, utility-driven agents.

In this workshop segment, you'll build a smart multi-agent pipeline that:
1. Extracts location entities from user input
2. Dynamically invokes a weather-fetching tool
3. Presents clear, friendly results to the user

This setup leverages FunctionTool from AutoGen 0.4+ and orchestrates agents using RoundRobinGroupChat. Let’s dive in 👇

### 👤 Why we use `UserProxyAgent`
Since the goal of our agentic workflow is to extract entities from human input, we have to rely on `UserProxyAgent`—AutoGen's built-in interface that captures user responses during a multi-agent conversation.

`user_proxy = UserProxyAgent(name="user_proxy")` creates a “listener” inside the AI system that speaks on your behalf. Think of it like inviting yourself into a team conversation among smart assistants. This part of the code makes sure there’s always a spot saved for you to jump in and say, “Here’s what I want” or “Let me explain.” When the AI team needs real details from a human, this listener gently pauses the conversation and lets you talk. Then, the rest of the team picks up what you said and uses it to do their job like finding specific information or organizing your thoughts.

You’ll see this line:

```python
user_proxy = UserProxyAgent(name="user_proxy")

```python
# -------------------------------
# 📦 Standard Library
# -------------------------------

import os                    # Used to access environment variables like API keys
import asyncio               # Enables asynchronous execution across the pipeline
from dotenv import load_dotenv  # Loads .env configuration into environment

# -------------------------------
# 🧠 AutoGen Core & AgentChat
# -------------------------------

from autogen_core import CancellationToken          # (Optional) for canceling long tasks
from autogen_agentchat.agents import UserProxyAgent, AssistantAgent  # Define agent roles
from autogen_agentchat.teams import RoundRobinGroupChat              # Sequential chat engine
from autogen_agentchat.ui import Console                            # (Unused UI streaming)
from autogen_agentchat.conditions import TextMentionTermination     # Stops task when keyword appears
from autogen_agentchat.base import TaskResult                       # (Unused) Result container
from autogen_core.tools import FunctionTool                         # Registers callable tools
from autogen_agentchat.messages import BaseMessage                  # Structured chat messages

# -------------------------------
# 🔗 External Models & Tools
# -------------------------------

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  # Azure OpenAI backend

# -------------------------------
# 🔧 Load environment variables
# -------------------------------

load_dotenv()  # Automatically loads secrets from .env file for flexibility

# Pull Azure OpenAI settings from environment
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Show model info in terminal
print("🔌 Endpoint:", azure_openai_endpoint)
print("🧠 Model:", azure_openai_model_name)
print("📅 API Version:", azure_openai_api_version)

# -------------------------------
# ☁️ Define Weather Tool
# -------------------------------

async def get_weather_details(city: str) -> dict:
    """
    Fetches structured weather information from wttr.in for a given city.
    Returns temperature, wind, humidity, sunrise/sunset, etc.
    """
    import requests
    url_c = f"https://wttr.in/{city}?format=%C|%t|%w|Humidity:%h|Sunrise:%S|Sunset:%s"        # Celsius
    url_f = f"https://wttr.in/{city}?format=%C|%t|%w|Humidity:%h|Sunrise:%S|Sunset:%s&u"      # Fahrenheit

    try:
        # Make request and parse response into fields
        resp_c = requests.get(url_c, timeout=10).text.strip()
        resp_f = requests.get(url_f, timeout=10).text.strip()
        keys = ["condition", "temperature", "wind", "humidity", "sunrise", "sunset"]

        return {
            "location": city.title(),
            # Celsius response available, but skipped
            #"celsius": dict(zip(keys, resp_c.split("|"))),
            "fahrenheit": dict(zip(keys, resp_f.split("|"))),
        }

    except Exception as e:
        # On failure, return empty structure with error
        return {
            "error": str(e),
            "location": city,
            "celsius": {},
            "fahrenheit": {}
        }

# Register tool using FunctionTool — canonical approach in AutoGen 0.4+
weather_tool = FunctionTool(
    func=get_weather_details,  # 🔧 Reference actual function
    name="get_weather_details",  # 🏷️ Tool name
    description="Returns weather info for a given city"  # 📘 Docs for LLM usage
)

#weather_tool.schema  # Optional check of OpenAPI-like schema

# -------------------------------
# 🚀 Initialize Agents and Team
# -------------------------------

async def initialize_ai_agent_team():
    """
    Sets up the multi-agent pipeline and runs a sample weather query.
    """

    # 🔗 Create a model client connected to Azure OpenAI
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    # 👤 Agent that represents the user input
    user_proxy = UserProxyAgent(name="user_proxy")

    # 🧠 Agent that extracts city and decides if weather query is needed
    weather_planner = AssistantAgent(
        name="weather_planner",
        model_client=model_client,
        system_message="""
        You are a weather assistant that analyzes user input and determines whether current 
        weather information should be retrieved for a specific location.

        Extract the city from the message and call get_weather_details.
        """
    )

    # 🔍 Agent that uses the tool to fetch weather data
    weather_fetcher = AssistantAgent(
        name="weather_fetcher",
        model_client=model_client,
        tools=[weather_tool],  # 🔧 Attach tool
        system_message="""
        Use tools to solve tasks to retrieve weather data using get_weather_details given a validated city.
        """
    )

    # 💬 Agent that formats the weather output for the user
    weather_responder = AssistantAgent(
        name="weather_responder",
        model_client=model_client,
        system_message="""
        Take the structured weather data and present it in a clear, concise conversational format using Markdown. 
        Make it feel like you're speaking directly to a curious human — walk through the temperature, 
        conditions, and any notable alerts with friendly clarity. Once you're done, end the message with the word TERMINATE.
        """
    )

    # 🧑‍🤝‍🧑 Set up RoundRobin dispatch between agents
    team = RoundRobinGroupChat(
        [user_proxy, weather_planner, weather_fetcher, weather_responder],
        termination_condition=TextMentionTermination("TERMINATE")  # Stops once "TERMINATE" is mentioned
    )

    # 💡 Default query — you'll be prompted to change it at runtime
    # 🌟 This is the beauty of AutoGen — user_proxy simulates a human, but can also prompt you live
    user_message = "What's the weather like in Irvington, NJ today?"
    stream = team.run_stream(task=user_message)

    # 🔁 Stream each message from the team as it arrives
    async for item in stream:
        if isinstance(item, BaseMessage):
            print(f"\n🔹 {item.source}:")
            print(item.content)


# -------------------------------
# 🏁 Entry Point
# -------------------------------

async def main():
    """
    Main entry point for launching the AI team.
    """
    await initialize_ai_agent_team()

# ⏯️ Runs async main if script is executed directly
if __name__ == "__main__":
    asyncio.run(main())
```
