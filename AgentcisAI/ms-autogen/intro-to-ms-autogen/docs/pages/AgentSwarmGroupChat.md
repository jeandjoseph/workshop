## 🧠 Understanding `Swarm` in Microsoft AutoGen

In Microsoft AutoGen 0.4+, a [`Swarm`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/swarm.html) is a coordination pattern where multiple agents contribute in parallel, each offering role-specific input. A proxy or selector agent dynamically aggregates these responses forwarding, combining, or discarding them as needed, creating an intelligent, non-linear hand-off process that mirrors a collaborative brainstorming session without hardwired agent-to-agent dependencies.


### 🧩 Why Swarm Works Well in Business

| Benefit                | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| 🕸️ Decentralization     | Reduces bottlenecks and avoids single points of failure                    |
| ⚡ Speed & Parallelism  | Agents operate simultaneously, accelerating insights and task completion   |
| 🧩 Modular Expertise    | Allows each agent to specialize, improving clarity and reuse               |
| 🔄 Adaptability         | Swarms flexibly respond to changing inputs or business conditions          |
| 📊 Transparent Logging  | Agent responses are traceable for auditability and compliance              |


### 🔬 Comparison `SelectOneGroupChat` with `RoundRobinGroupChat`

| Strategy               | Determinism       | Agent Turn Logic                         | Best For                                       |
|------------------------|-------------------|------------------------------------------|------------------------------------------------|
| [`SwarmGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/swarm.html)       | Non-deterministic | All agents respond simultaneously        | Collective brainstorming, high-parallelism     |
| [`SelectOneGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html)   | Non-deterministic | LLM selects one agent to respond         | Focused replies, expert selection, Expert Q&A, focused dialog              |
| [`RoundRobinGroupChat`](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.teams.html#autogen_agentchat.teams.RoundRobinGroupChat)  | Deterministic     | Fixed circular order                     | Equal participation, structured dialogue, Panel-style debates, brainstorming       |
---

Great, now that you’ve got a solid grasp of `Swarm` and how it differs from `SelectOneGroupChat` and `RoundRobinGroupChat`, let’s dive into the hands-on setup.

#### ✅ Steps to follow:
1. Activate your Python virtual environment. Make sure it's up and running without issues.
2. **Copy** and **Paste** the code below into a text editor. You can use something simple like Notepad.

```python
# Import standard and third-party libraries
import os
import asyncio
from dotenv import load_dotenv

# Import AutoGen classes for Azure OpenAI integration and agent orchestration
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import Swarm
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_agentchat.base import TaskResult

# Load environment variables from a .env file for secure configuration
load_dotenv()

# Retrieve Azure OpenAI configuration from environment
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

# Display retrieved configuration in console for verification
print("Endpoint:", azure_openai_endpoint)
print("Model:", azure_openai_model_name)
print("API Version:", azure_openai_api_version)

# Define asynchronous execution function for orchestrating Swarm agent conversation
async def run_swarm_team(user_message):
    # Initialize model client for interacting with Azure OpenAI endpoints
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key
    )

    # Define DataEngineer agent responsible for data ingestion and preprocessing
    DataEngineer = AssistantAgent(
        name="DataEngineer",
        description="Builds scalable pipelines and ensures data reliability.",
        model_client=model_client,
        handoffs=["DataAnalyst", "ReportBuilder"],
        system_message="""
        You are a Data Engineer tasked with making raw data usable.

        ⚙️ Responsibilities:
        - Design and document scalable data pipelines.
        - Very concisely explain transformations to cleanse and validate data integrity.
        - Handoffs to 'DataAnalyst' for any steps required to Discovers patterns, trends, and insights from structured data.
        - Handoffs to 'ReportBuilder' for any steps required ReportBuilder (for creating visualizations, reports and dashboard).

        🛑 Handoff Logic:
        - Await agent approval before concluding.
        - Use "TERMINATE" when your plan has been validated and is complete.
        """
    )

    # Define DataAnalyst agent responsible for uncovering insights from cleaned data
    DataAnalyst = AssistantAgent(
        name="DataAnalyst",
        description="Discovers patterns, trends, and insights from structured data.",
        model_client=model_client,
        handoffs=["DataEngineer", "ReportBuilder"],
        system_message="""
        You are a DataAnalyst. You analyze cleaned data to reveal insights.

        ⚙️ Responsibilities:
        - Focus only on discovers patterns, trends, and insights from structured data
        - Handoffs to 'DataEngineer' for any steps required to transform, clean, and validate incoming data.
        - Handoffs to 'ReportBuilder' for any steps required creating visualizations, reports and dashboard.
        - Be very clear, modular, and brief in your planning.

        🔄 Delegation Logic:
        - Do not delegate unless the recipient agent's scope matches the task context exactly.
        - Await confirmation before finalizing.

        🛠️ Engagement Flow:
        - If Analytic hits data problems, escalate to 'DataEngineer'.
        - If no problem found handoffs to 'ReportBuilder'.
        - Wrap up clearly and end with "TERMINATE" once satisfied.
        """
    )

    # Define ReportBuilder agent responsible for visualizing insights and crafting reports
    ReportBuilder = AssistantAgent(
        name="ReportBuilder",
        description="Visualizes insights and crafts strategic reports.",
        model_client=model_client,
        #handoffs=["DataEngineer", "DataAnalyst"],
        system_message="""
        You are ReportBuilder—responsible for turning insights into clear, executive-ready outputs.

        📊 Responsibilities:
        - Focus only on Creating dashboards, charts, and formatted reports.
        - Avoid digging into raw data or performing analysis yourself.
        - Delegate issues upstream when needed.

        🛠️ Engagement Flow:
        - If visualization hits data problems, escalate to 'DataEngineer'.
        - If output lacks insight, ping 'DataAnalyst' for clarification.
        - Wrap up clearly and end with "TERMINATE" once satisfied.
        """
    )

    # Set swarm termination conditions: stop after 5 messages or when "TERMINATE" is mentioned
    termination_condition = TextMentionTermination("TERMINATE") | MaxMessageTermination(max_messages=5)
    
    # Create a Swarm team with all agents and the defined termination logic
    team = Swarm(
        participants=[DataAnalyst, DataEngineer, ReportBuilder],
        termination_condition=termination_condition
    )

    # Run asynchronous message exchange loop and display each agent’s output
    async for res in team.run_stream(task=user_message):
        if hasattr(res, "source") and hasattr(res, "content"):
            print(f"{res.source}: {res.content}\n")

# Main loop for capturing user input and executing the swarm conversation
if __name__ == "__main__":
    while True:
        user_message = input("Enter your message (type 'done' to exit): ").strip()
        if user_message.lower() == 'done':
            print("Conversation terminated.")
            break
        asyncio.run(run_swarm_team(user_message))
```

```text
Before starting, list the available agents and explicitly assign one to each of the following roles: data ingestion, cleaning, saving, pattern/trend/insight discovery, and reporting. Then, outline the plan using short, numbered steps that summarize each agent’s intended actions. Once all assigned tasks are completed, confirm that the dataset is fully prepared for analysis and reporting. This prompt structure promotes clarity, modularity, and consistent handoff behavior in agentic workflows.
```

image

![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/Swarm_script1_img_1.png)
<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/AgentSelectorGroupChat.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/AgentSwarmGroupChat.md">Next Page →</a>
    </td>
  </tr>
</table>
