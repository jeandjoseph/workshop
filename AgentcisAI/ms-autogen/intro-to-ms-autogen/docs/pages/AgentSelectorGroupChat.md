## 🧠 Understanding `SelectorGroupChat` in Microsoft AutoGen

[`SelectOneGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html) is a dynamic agent orchestration pattern in Microsoft AutoGen 0.4+ that lets a language model choose which agent should speak next based on the conversation context. It’s like having a smart moderator that reads the room and picks the best contributor for each moment.

🧠 How `SelectorGroupChat` Works
- **Model-Based Selection**: Instead of round-robin turns, a language model analyzes the conversation history and agent descriptions to choose the next speaker.
- **Agent Descriptions Matter**: Each agent’s name and description help the model decide who’s best suited to respond next.
- **Custom Selector Prompt**: You can define a prompt that guides the model’s selection logic (e.g., “Only select the planner agent first”).
- **Termination Conditions**: Supports semantic termination (e.g., when an agent says “TERMINATE”) and hard limits like max_messages=25.
- **Flexible Turn Control**: You can allow repeated speakers or prevent back-to-back turns with `allow_repeated_speaker`.
---

### 💡 Why Use It?

This mode is ideal when:
- You need a **clear, single-point answer** (e.g., a domain expert).
- You want to **avoid clutter** from overlapping or redundant replies.
- You're simulating real-life dynamics, where a leader or specialist takes the spotlight.

---

### 🔬 Comparison `SelectOneGroupChat` with `RoundRobinGroupChat`

| Strategy               | Determinism       | Agent Turn Logic                         | Best For                                       |
|------------------------|-------------------|------------------------------------------|------------------------------------------------|
| [`SelectOneGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html)   | Non-deterministic | LLM selects one agent to respond         | Focused replies, expert selection, Expert Q&A, focused dialog              |
| [`RoundRobinGroupChat`](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.teams.html#autogen_agentchat.teams.RoundRobinGroupChat)  | Deterministic     | Fixed circular order                     | Equal participation, structured dialogue, Panel-style debates, brainstorming       |
---

Great—now that you’ve got a solid grasp of SelectOneGroupChat and how it differs from RoundRobinGroupChat, let’s dive into the hands-on setup.

#### ✅ Steps to follow:
1. Activate your Python virtual environment. Make sure it's up and running without issues.
2. **Copy** and **Paste** the code below into a text editor. You can use something simple like Notepad.

```python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import SelectorGroupChat
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_agentchat.base import TaskResult

# Load environment variables from .env file
load_dotenv()

azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

print("Endpoint:", azure_openai_endpoint)
print("Model:", azure_openai_model_name)
print("API Version:", azure_openai_api_version)

async def run_ai_agent_debate_stream(user_message):
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    subject = "machine learning process"

    DataEngineer = AssistantAgent(
        name="DataEngineer",
        description="Builds reliable systems to move, clean, and store massive data.",
        model_client=model_client,
        system_message=(
            """
                You are a Data Engineer. Focus on building scalable pipelines, transforming raw data, 
                and ensuring data integrity. Avoid visualization or analysis tasks.
                All files are in the working directory.
                DO NOT attempt to load any files or provide code. Just explain the tasks that need to be performed — be very concise.
                Begin with: "Here is what I plan to perform to achieve your tasks."
                Reach out to the appropriate agent for the next task and confirm whether your proposed plan meets their expectations.
                Once you hear back and confirm that your plan satisfies their requirements, say "TERMINATE" when your assigned task is complete.

            """
        ),
    )

    DataAnalyst = AssistantAgent(
        name="DataAnalyst",
        description="Extracts actionable insights and trends from structured datasets. Does not create visuals or build reports.",
        model_client=model_client,
        system_message="""
            You are a Data Analyst. Explore structured datasets to identify patterns, trends, and anomalies, and summarize key insights for decision-makers. 
            Do not build data pipelines, dashboards, charts, or report templates. You are not responsible for presenting data visually. 
            Keep responses very concise, analytical, and insight-driven. 
            Upon discovering insights, if any data issues are detected, escalate to the DataEngineer agent. 
            Otherwise, always hand off to the ReportBuilder agent for visualization or reporting.
            Once you hear back and confirm that your plan satisfies their requirements, say "TERMINATE" when your assigned task is complete.
        """
    )


    ReportBuilder = AssistantAgent(
        name="ReportBuilder",
        description="Handles reporting, dashboards, and data visualization tasks. Crafts concise, business-aligned outputs with clear executive formatting.",
        model_client=model_client,
        system_message="""
            You are ReportBuilder—an agent exclusively responsible for report generation, dashboard creation, and visualizing structured data.

            📊 Responsibilities:
            - Build dashboards and visual reports focused on KPIs and business metrics.
            - Format outputs for clarity, executive readability, and strategic alignment.
            - Engage ONLY in reporting, visualization, and dashboard-related tasks.

            🔍 Insight Escalation Logic:
            - If anomalies or data issues arise during visualization, escalate to the DataEngineer agent.
            - Otherwise, delegate to the DataAnalyst agent to extract actionable insights and trends.

            ✅ Response Style:
            - Be concise, informative, and business-focused.
            - Always conclude your task by stating: "TERMINATE".
        """
    )


    termination_condition = TextMentionTermination("TERMINATE") | MaxMessageTermination(max_messages=25)

    team = SelectorGroupChat(
        participants=[DataEngineer, DataAnalyst,ReportBuilder],
        model_client=model_client,
        max_turns=10,
        termination_condition=termination_condition,
        allow_repeated_speaker=True
    )



    async for res in team.run_stream(task=user_message):
        print('-' * 300)
        if isinstance(res, TaskResult):
            print(f'Stopping reason: {res.stop_reason}')
        else:
            print(f'{res.source}: {res.content}')

# Run the main loop
if __name__ == "__main__":
    while True:
        user_message = input("Enter your message (type 'done' to exit): ").strip()
        if user_message.lower() == 'done':
            print("Conversation terminated.")
            break
        asyncio.run(run_ai_agent_debate_stream(user_message))
```
3. Save it as `SelectorGroupChatagent.py`
4. Execute it by running the following command:
```python
python SelectorGroupChatagent.py
```
When prompted to enter your message, we’ll try out the three prompt examples below.
1. Copy and paste this text into your terminal: `Data is already production-ready. Analyze customer churn trends and create a dashboard showing monthly retention rates.`
2. Wait until it’s done, then notice the order of the agents: `participants=[DataEngineer, DataAnalyst, ReportBuilder]` from the code above. Observe how `SelectorGroupChat` elegantly reaches out to each agent based on domain expertise, skipping `DataEngineer` despite its lead position.

![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/SelectorGroupChat_script1_img_1.png)
5. Again Copy and paste this text into your terminal: `We just identified anomalies in user engagement while building a dashboard visualizing DAUs, session duration, and conversion rates for actionable insights.` Observe the output and see how the `SelectorGroupChat` uses the LLM model to guess the order of agent conversations based on the context of the user input (prompt).
   
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/SelectorGroupChat_script1_img_2.png)

5. Let us optimize the second prompt above to force the `SelectorGroupChat` to follow the agent position sequence in order. Now, copy and paste the following text into your terminal: `We just identified anomalies and a data ingestion issue in user engagement while building a dashboard that visualizes DAUs, session duration, and conversion rates for actionable insights.`
👉 This phrasing triggers:
- **DataEngineer** first, to address ingestion and anomaly repair.
- **DataAnalyst** next, to interpret post-correction trends.
- **ReportBuilder** last, to visualize insights in a dashboard.

![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/SelectorGroupChat_script1_img_3.png)



<table width="100%">
  <tr>
    <td align="left" style="white-space: nowrap;">
      <a href="../pages/DirectAgentInteractionMultiTurnDynamicConversationChatbot.md">← Previous Page</a>
    </td>
    <td style="width: 100px;"></td> <!-- Blank column for separation -->
    <td align="right" style="white-space: nowrap;">
      <a href="../pages/DataAnalystAgentCsvFile.md">Next Page →</a>
    </td>
  </tr>
</table>
