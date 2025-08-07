## 🤖 Designing [Agent](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/agents.html) Responses with AssistantMessage in AutoGen
In agentic systems, the intelligence of interaction stems not just from user input, but from how agents interpret, reason, and respond. At the heart of this is the [AssistantAgent](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/agents.html) a core AutoGen component designed to generate structured, context-aware replies. This demo explores how `AssistantAgent` produces and utilizes [AssistantMessage](https://microsoft.github.io/autogen/stable/reference/python/autogen_core.models.html#autogen_core.models.AssistantMessage), the standardized output format that encapsulates an agent’s reply, rationale, or next action.

Whether you're orchestrating a single-agent assistant or coordinating a multi-agent workflow, AssistantMessage is the expressive protocol through which `AssistantAgent` communicates. It ensures that every response is not just model output, but a traceable, interpretable unit of agentic reasoning.

To demonstrate `AssistantMessage`, we use [RoundRobinGroupChat](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.teams.html#autogen_agentchat.teams.RoundRobinGroupChat) a [team](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/agents.html) class that coordinates sequential turn-taking among [AssistantAgent](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.agents.html#autogen_agentchat.agents.AssistantAgent) instances. Each reply is encapsulated in an `AssistantMessage`, forming a clean, predictable loop where agents build on prior outputs to execute tasks autonomously, with or without human intervention.

### 🔁 RoundRobinGroupChat – Deterministic
- **How it works**: Agents take turns in a fixed, circular order.
- **Behavior**: Every agent gets a chance to respond in sequence, and each response is broadcast to all other agents.
- **Use case**: Ideal for structured collaboration where each agent contributes equally and context is shared.
- **Key trait**: Deterministic - the order of agent turns is predictable and repeatable.
- **Example**: Agent A → Agent B → Agent C → Agent A...

This is useful when you want fairness and transparency in agent participation.

it's important to differentiate between post-hoc analysis and real-time visibility when working with AssistantMessage, as [run()](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.agents.html#autogen_agentchat.agents.BaseChatAgent.run) and [run_stream()](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.agents.html#autogen_agentchat.agents.BaseChatAgent.run_stream) surface messages in distinct ways:

In `asyncio`, we distinguish between `run()` and `run_stream()`:
- `run()` executes the full conversation and returns a final [TaskResult](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.base.html#autogen_agentchat.base.TaskResult), which includes the complete set of messages (including AssistantMessage) after the interaction concludes.
- `run_stream()` is an asynchronous generator that yields each intermediate message such as AssistantMessage, tool calls, and events in real time, followed by the final `TaskResult`.

This distinction is crucial when deciding between post-hoc analysis and real-time visibility. Use `run()` for batch-style workflows, and `run_stream()` when you need granular insight, live monitoring, or reactive UI integration.


### 👉 Let’s Proceed with the Demo: Agent Dialogue via `RoundRobinGroupChat`

This part of the workshop demonstrates how two AI agents **Jean** and **Daniel** engage in a structured, turn-based dialogue using AutoGen’s **deterministic** `RoundRobinGroupChat` strategy.

Each agent responds in sequence, and every reply is encapsulated in an `AssistantMessage` object. These messages preserve not only the content but also the agent’s reasoning and context, making the conversation traceable and reproducible.

The flow is governed by a predefined [`max_turns`](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.agents.html) limit, ensuring the exchange remains focused and time-bound.


### What to Expect:
- 🤖 **Deterministic agent selection**: **Jean** and **Daniel** take turns in a predictable order.
- 📦 **Structured replies**: Each response is wrapped in an `AssistantMessage`, enabling inspection and downstream processing.
- 🔄 **Autonomous collaboration**: Agents simulate real conversation dynamics without human intervention.
- 🧪 **Reproducible behavior**: The looped interaction can be rerun with consistent results, ideal for debugging or demonstration.

This setup showcases how AutoGen agents can collaborate intelligently in a controlled loop, perfect for modeling agentic workflows, testing prompt strategies, or building multi-agent systems.

### ✅ Steps to complete this demo:
1. 🛠️ Before you begin, make sure your [Python virtual environment](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/pages/GettingEnvReady.md) is activated, all dependencies are installed, and your `.env` file is properly configured. Everything should be running smoothly before you proceed.
2. Copy & Paste the code below into a text editor. You can use something simple like Notepad.

````bash
import os
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
import asyncio


# Load environment variables from .env file
load_dotenv()

# Retrieve environment variables
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Print retrieved environment variables
print(azure_openai_endpoint)
print(azure_openai_model_name)
print(azure_openai_api_version)


# Define an async function to interact with the model client
async def interact_with_model(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    # Create a user message and get the response from the model client
    subject = "clean datasets in the machine learning process"
    Jean = AssistantAgent(
     name="Jean",
        model_client=model_client,
        system_message=(
            "You are Jean, a Data Engineer. "
            "Your task is to clearly and very concisely explain the importance of {subject}. "
            "Focus on being very brief, direct, and informative. "
            "Make sure you introduce yourself as Jean, a Data Engineer, at only the start of the first conversation. "
     ),
    )


    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            "You are Daniel, an AI Engineer. "
            "Begin conversations by discussing anout the {subject}. "
            "Be very concise and focus specifically on data cleansing and feature engineering. "
            "Make sure you introduce yourself as Daniel, an AI Engineer, at only the start of the first conversation."
     ),
    )

    team = RoundRobinGroupChat(
        participants=[Daniel, Jean],
        max_turns=3,
    )
   
    res= await team.run(task=user_message)
    
    for message in res.messages:
        print('='*100)
        print(f"{message.source}: {message.content}")

# Loop to get user input until "done" is typed
def main():
    while True:
        user_input = input("Enter your message (type 'done' to exit): ").strip()
        if user_input.lower() == "done":
            break
        asyncio.run(interact_with_model(user_input))

# Run the main loop
if __name__ == "__main__":
    main()
````

3. Save the file as `autogen_fixed_turn_demo_run.py`. Choose a folder where your virtual environment can easily access it.
5. Run the script using the terminal: Observe how the agents communicate in a multi-turn conversation with deterministic sequencing.
```python
python autogen_fixed_turn_demo_run.py
```
6. When prompted, type **Data Cleansing** as shown below, then press **Enter**.
   ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script1_img_1.png)
8. Wait until the execution is complete, then you will see a screen similar to the one shown below.
   ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script1_img_2.png)


Notice that in a `RoundRobinGroupChat`, the order of agents in the participants list directly determines the turn-taking sequence. For example, if `participants = [Daniel, Jean]`, Daniel will respond first, followed by Jean, then back to Daniel, and so on alternating strictly in that order. Changing it to `participants = [Jean, Daniel]` means Jean takes the first turn, followed by Daniel, and the cycle continues from there.

🔁 Here’s an example: Replace your original Team participant setup with the script below. The listed order defines the flow of the conversation and be sure to preserve indentation, or the script may fail:
- Type `done`, press **Enter**, then **copy and paste** the code below to overwrite the existing team group chat.

```python
team = RoundRobinGroupChat(
    participants=[Jean, Daniel],
    max_turns=3,
)
```
- 💾 Save your changes, then run the following code to execute the updated script:
```python
python autogen_fixed_turn_demo_run.py
```

With the small change above, `participants=[Jean, Daniel]`, we can clearly see that it affects the sequence flow of the conversation **Jean** now speaks first, followed by **Daniel**, as shown below.
  ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script1_img_3.png)


We just explored `asyncio.run()`, which waits for the entire conversation to finish before showing results. Now, let’s shift to `run_stream()`. The key difference is that `run_stream()` is an async generator it lets us observe the conversation step by step as it unfolds. Unlike regular functions that reset after returning, generators remember where they left off and resume from the last yield, making them perfect for interactive, real-time experimentation.

When using `run_stream()`, make sure to import `TaskResult` with `from autogen_agentchat.base import TaskResult`. This is essential because each step in the stream yields a TaskResult object, which holds the intermediate output of the conversation. Without this import, you won’t be able to properly access or interpret the streamed results as they come in.

### 🔄 `run_stream()`. Code Update Summary

🔧 In this version, we made three key changes:

- 1️⃣ Replaced the blocking `run()` call with the streaming `run_stream()` to observe the conversation step by step and capture real-time outputs. 
- 2️⃣ `TaskResult` indicates why the chat stopped (e.g. max_turns, tool_use_limit) and optionally includes final results for post-processing. 
- 3️⃣ 🧹 Removed the looped conversation logic to focus on a single, streamable interaction for clarity and experimentation.

```python
# ❌ Old approach from above scripts
res = await team.run(task=user_message)
for message in res.messages:
    print('='*100)
    print(f"{message.source}: {message.content}")
`````

### ✅ New approach using `run_stream`
```python
async for res in team.run_stream(task=user_message):
    print('='*100)
    if isinstance(res, TaskResult):
        print(f'Stopping reason: {res.stop_reason}')
    else:
        print(f'{res.source}: {res.content}')
```
>
🚀 To experience real-time agent interactions with `run_stream()`, replace your existing Python script entirely with the code snippet below, save and run it. This version enables step-by-step observation of agent responses as the conversation unfolds.

Make sure to close your previous conversation by typing `done` and pressing **Enter**, or by pressing **Ctrl+C**. Then proceed with the tasks below.

````python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.base import TaskResult

# Load environment variables from .env file
load_dotenv()

# Retrieve environment variables
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# Print retrieved environment variables
print("Endpoint:", azure_openai_endpoint)
print("Model:", azure_openai_model_name)
print("API Version:", azure_openai_api_version)

# Define an async function to interact with the model client
async def run_ai_agent_debate(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    subject = "clean datasets in the machine learning process"

    Jean = AssistantAgent(
        name="Jean",
        model_client=model_client,
        system_message=(
            f"You are Jean, a Data Engineer. "
            f"Your task is to clearly and very concisely explain the importance of {subject}. "
            f"Focus on being very brief, direct, and informative. "
            f"Make sure you introduce yourself as Jean, a Data Engineer, at only the start of the first conversation."
        ),
    )

    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            f"You are Daniel, an AI Engineer. "
            f"Begin conversations by discussing about the {subject}. "
            f"Be very concise and focus specifically on data cleansing and feature engineering. "
            f"Make sure you introduce yourself as Daniel, an AI Engineer, at only the start of the first conversation."
        ),
    )

    team = RoundRobinGroupChat(
        participants=[Daniel, Jean],
        max_turns=3,
    )

    async for res in team.run_stream(task=user_message):
        print('-' * 20)
        if isinstance(res, TaskResult):
            print(f'Stopping reason: {res.stop_reason}')
        else:
            print(f'{res.source}: {res.content}')

# Run the main loop
if __name__ == "__main__":
    user_message = input("Enter your message (type 'done' to exit): ").strip()
    if user_message.lower() != 'done':
        asyncio.run(run_ai_agent_debate(user_message))
````

🔁 Re-run the Python script.  
📥 When prompted, type `Data Cleansing`, then press **Enter** to proceed.


### 👀 Observation During `run_stream()` Execution

Notice that during execution with `run_stream()`, we can observe the conversation unfold **step by step** in real time. Each message is streamed as it’s generated, allowing us to monitor the interaction live unlike `run()`, which only shows the full conversation after it completes. This makes `run_stream()` ideal for debugging, experimentation, and interactive applications.

📌 Notice: We have **Stopping reason: Maximum number of turns (3) reached** in the screenshot below.  
- The conversation stopped due to `max_turns=3` a parameter that limits the number of message exchanges in the agent group.
- 🛠️ You can adjust this value in the group chat settings or directly in the `AgentChatGroup` initialization depending on your AutoGen setup.
  ![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script2_img_1.png)

🔍 Let’s go over the different ways an agent conversation might end and in this case, what triggered the termination.

### 🔢🛑 Balancing Turn Limits with Semantic Termination in AutoGen 0.4+
In the above demo, the [max_turns](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.teams.html) parameter enforces a hard cap on the number of agent responses, using `MaxMessageTermination` to ensure the conversation ends predictably. This is ideal for controlled experiments, debugging, and reproducible demos, especially when showcasing agent behavior in a fixed number of steps. However, it can prematurely cut off meaningful exchanges if agents are mid-task or require more turns to reach consensus, making it less suitable for open-ended or goal-driven interactions.

To address this limitation, AutoGen 0.4 introduces [TextMentionTermination](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.conditions.html#autogen_agentchat.conditions.TextMentionTermination), which halts the conversation when a specific keyword (e.g., "TERMINATE" or "APPROVE") appears in any message. This allows agents to self-signal completion based on semantic cues rather than arbitrary limits, enabling more natural and context-aware termination. Combining both conditions (e.g., MaxMessageTermination | TextMentionTermination) offers a flexible safety net, ensuring runs don’t hang indefinitely while still allowing agents to exit gracefully when their task is complete.

When building agentic AI systems with Microsoft AutoGen, it's important to think carefully about **how and when your agents should stop talking**. Parameters like `max_turns` and `TextMentionTermination` aren’t just technical details, they shape the flow, clarity, and usefulness of your conversations.

### 🛠️ What’s Modified in the thi Version

This demo focuses on enabling **Dynamic Multi-Turn Conversation** using a content-based stopping condition.

Here’s what we changed to improve clarity and control flow during real-time agent interactions:

### 1️⃣ Imported a semantic termination condition

This allows agents to end the conversation naturally by mentioning a specific keyword.

```python
from autogen_agentchat.conditions import TextMentionTermination
```

2️⃣ Applied the termination rule to the chat group

This ensures the conversation stops when an agent explicitly says "TERMINATE".

```python
termination_condition = TextMentionTermination(text="TERMINATE")`
```

3️⃣ Added a moderator agent for structured debate dynamics

Introducing a guiding voice helps the demo stay focused and provides contextual cues for when to stop.

```python
    Moderator = AssistantAgent(
        name='Moderator',
        model_client=model_client,
        system_message=(
            f"You are Garellard, the moderator of the debate between Jean and Daniel. Subject: {subject}. "
            "Announce each round, flag round 3 as final, and end with 'TERMINATE'."
        )
    )
```


🚀 To experience real-time agent interactions using `termination_condition`, completely replace your existing Python script with the snippet below. Save it and run the script to activate this version’s enhanced control flow and semantic termination.

📌 **Notice:** We’ve updated the `max_turns` parameter to 15.

- With the optimized prompt, the moderator is smart enough to [terminate](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.conditions.html#autogen_agentchat.conditions.TextMentionTermination) the conversation at the right moment using semantic cues.
- It's also important to highlight the role of the [CancellationToken](https://microsoft.github.io/autogen/stable/reference/python/autogen_core.html#autogen_core.CancellationToken), which allows external interruption of ongoing agent interactions when needed.

🚀 To explore `termination_condition` agent interactions using `run_stream()`, replace your existing Python script with the snippet below, then save and execute it by typing `Data Cleansing`. This version enables precise, semantic message termination triggered by configured agent conditions, perfect for demos and debugging workflows.

Make sure you close your previous conversation by pressing Ctrl+C, then proceed with the tasks below.

```python
import os, sys
import asyncio
from dotenv import load_dotenv

# 🤖 AgentChat and Azure OpenAI imports
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.base import TaskResult

# 🌱 Load environment variables from .env file
load_dotenv()

# 🔐 Retrieve Azure OpenAI credentials from environment
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

# 🚨 Windows compatibility for asyncio event loop
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

# 🧠 Setup debate team with agents and moderator
async def run_ai_agent_debate(subject):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    Jean = AssistantAgent(
        name="Jean",
        model_client=model_client,
        system_message=(
            f"You are Jean, a Data Engineer. Your task is to clearly and concisely explain the importance of {subject}. "
            "Introduce yourself only at the start of the first conversation."
            "Focus on being very brief, direct, and informative."
        ),
    )

    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            f"You are Daniel, an AI Engineer. Focus on {subject} with emphasis on data cleansing and feature engineering. "
            "Introduce yourself only at the start of the first conversation."
            "Focus on being very brief, direct, and informative."
        ),
    )

    Moderator = AssistantAgent(
        name='Moderator',
        model_client=model_client,
        system_message=(
            f"You are Garellard, the moderator of the debate between Jean and Daniel. Subject: {subject}. "
            "Announce each round, flag round 3 as final, and end with 'TERMINATE'."
        )
    )

    team = RoundRobinGroupChat(
        participants=[Moderator, Daniel, Jean],
        max_turns=15,
        termination_condition=TextMentionTermination(text="TERMINATE")
    )

    async for res in team.run_stream(task=user_message):
        print('-' * 300)
        if isinstance(res, TaskResult):
            print(f'Stopping reason: {res.stop_reason}')
        else:
            print(f'{res.source}: {res.content}')

# Run the main loop
if __name__ == "__main__":
    user_message = input("Enter your message (type 'done' to exit): ").strip()
    if user_message.lower() != 'done':
        asyncio.run(run_ai_agent_debate(user_message))
```
After running the script, you'll get a screen that looks like the one shown below.
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script3_img_1.png)

This shows the moderator isn’t just a passive agent, it’s a conversation architect with built-in judgment.

🎯 **Moderator**'s Key Roles in the Example
- 👋 **Welcoming Participants**: Clearly introduces all agents **Jean** and **Daniel** setting a professional, inclusive tone.
- 📚 **Structuring the Debate**: Splits the interaction into defined rounds: Opening Statements, Key Challenges, and Final Statements, creating a focused, time-boxed flow.
- 🧮 **Managing Turn Count**: Although max_turns is set to 15, the moderator enforces semantic rules (like termination triggers) to stop earlier, keeping things efficient.
- 🛑 **Early Termination Control**: Uses smart condition matching (e.g. message contains "TERMINATE") to override the default turn limit for graceful, content-aware shutdowns.

### 🧩 To Summarize

This demo walked you through the two core conversation strategies in Microsoft AutoGen: **Fixed Multi-Turn**, which uses `max_turns` for predictable, structured exchanges, and **Dynamic Multi-Turn**, which leverages `TextMentionTermination` for more natural, context-aware dialogue. Each approach serves different goals whether you're aiming for control or flexibility in agent behavior.

### **Optional Demo:** 
Turn the above snippet into a chatbot using Streamlit

**Real-life benefits for end users interacting via an interface:**
- 💬 Personalized Help: Users can ask questions and get agent responses tailored to their needs (e.g., workshop FAQs, support)
- 🧭 Guided Exploration: Chatbots can walk users through demos, tools, or learning modules step by step
- 📋 Real-time Feedback: Users can quickly share thoughts or satisfaction while the context is fresh
- 🖼️ Visual Interface: Conversational UI lowers cognitive load compared to navigating dense pages or forms


🚀 **Microsoft AutoGen 0.4+ is our primary focus.**  However, if you're interested in learning about Streamlit, please visit the [official website](https://docs.streamlit.io/).

To experience real-time Chatbot interactions using `streamlit`.

✅ Steps to complete this demo:
1. 📥 **Copy, paste, and completely replace** your existing Python script with the snippet below. 💾 Then, save the file as `autogen_chatbot_app.py` to apply the changes.

```python
import os, sys
import asyncio
from dotenv import load_dotenv

# 🤖 AgentChat and Azure OpenAI imports
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.base import TaskResult

# 🌱 Load environment variables from .env file
load_dotenv()

# 🔐 Retrieve Azure OpenAI credentials from environment
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

# 🚨 Windows compatibility for asyncio event loop
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

# 🧠 Setup debate team with agents and moderator
async def initialize_ai_debate_team(subject):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    Jean = AssistantAgent(
        name="Jean",
        model_client=model_client,
        system_message=(
            f"You are Jean, a Data Engineer. Your task is to clearly and concisely explain the importance of {subject}. "
            "Introduce yourself only at the start of the first conversation."
            "Focus on being very brief, direct, and informative."
        ),
    )

    Daniel = AssistantAgent(
        name="Daniel",
        model_client=model_client,
        system_message=(
            f"You are Daniel, an AI Engineer. Focus on {subject} with emphasis on data cleansing and feature engineering. "
            "Introduce yourself only at the start of the first conversation."
            "Focus on being very brief, direct, and informative."
        ),
    )

    Moderator = AssistantAgent(
        name='Moderator',
        model_client=model_client,
        system_message=(
            f"You are Garellard, the moderator of the debate between Jean and Daniel. Subject: {subject}. "
            "Announce each round, flag round 3 as final, and end with 'TERMINATE'."
        )
    )

    return RoundRobinGroupChat(
        participants=[Moderator, Daniel, Jean],
        max_turns=15,
        termination_condition=TextMentionTermination(text="TERMINATE")
    )

# 📡 Run debate stream and update UI with messages
async def run_debate_and_stream(team):
    import streamlit as st  # ✅ Move import here before usage
    message_container = st.empty()
    content_buffer = []

    async for message in team.run_stream(task="Start the debate!"):
        if isinstance(message, TaskResult):
            formatted = f"🛑 **Stopping reason**: {message.stop_reason}"
        else:
            formatted = f"**{message.source}**: {message.content}"
        content_buffer.append(formatted)
        message_container.markdown("\n\n".join(content_buffer))

# 🖼️ Streamlit UI components (imported right before use)
import streamlit as st  # ✅ Primary import for Streamlit interface
st.set_page_config(page_title="AI Debate Arena", layout="wide")
st.title("🧠💬 AI Debate Arena")

# 📝 Capture user input for debate topic
topic = st.text_input("Enter debate topic:", value="type any kind of topics")
start_button = st.button("Start Debate")

# ⚙️ Initialize Streamlit session state
if "messages" not in st.session_state:
    st.session_state.messages = []
if "debate_triggered" not in st.session_state:
    st.session_state.debate_triggered = False

# ▶️ Start debate if triggered
if start_button and topic and not st.session_state.debate_triggered:
    async def debate_sequence():
        team = await initialize_ai_debate_team(topic)
        await run_debate_and_stream(team)

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(debate_sequence())

# 💬 Display message history after debate
st.markdown("---")
for msg in st.session_state.messages:
    st.markdown(msg)
```


2. **Open your terminal**, then run:
```bash
streamlit run autogen_chatbot_app.py
```
After the script finishes running, a screen like the one below will appear.
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script4_img_1.png)

3. 🌐 Once the Streamlit App Opens in Your Browser, Follow These Steps:
    1. Go to the local Streamlit URL-usually `http://localhost:8502/`.
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script4_img_2.png)
    3. Find the input box labeled **Enter debate topic**.
    4. Type in a topic of your choice, such as `Data Cleansing`.
    5. Click the **Start Debating** button.
    6. Observe the live debate unfold between three AI agents as they take turns discussing the topic.
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/RoundRobinGroupChat_script4_img_3.png)



### ✨ Share Your Experience and Satisfaction

🙏 We hope you found this experience insightful! If you enjoyed the demos or learned something new, we’d love to hear your feedback. Feel free to share this page on social media to help us reach even more people interested in Agentic AI.


✅ By now, you have a solid understanding of the **RoundRobinGroupChat** conversation flow.  
🚀 Let's shift gears and dive into **SelectorGroupChat** by clicking on **Next Page**.


<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/DirectHumanInteraction.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/AgentSelectorGroupChat.md">Next Page →</a>
    </td>
  </tr>
</table>




