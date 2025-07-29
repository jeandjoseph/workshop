## 🧠 Understanding `SelectorGroupChat` in Microsoft AutoGen

[`SelectOneGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html) is a coordination mode where **only one agent responds at a time**, hand-picked for its relevance to the task or prompt. Unlike traditional group chat strategies that allow multiple responses (like `RoundRobinGroupChat`), this method keeps interactions **focused and streamlined**.

---

🧠 How `SelectorGroupChat` Works
- **Model-Based Selection**: Instead of round-robin turns, a language model analyzes the conversation history and agent descriptions to choose the next speaker.
- **Agent Descriptions Matter**: Each agent’s name and description help the model decide who’s best suited to respond next.
- **Custom Selector Prompt**: You can define a prompt that guides the model’s selection logic (e.g., “Only select the planner agent first”).
- **Termination Conditions**: Supports semantic termination (e.g., when an agent says “TERMINATE”) and hard limits like max_messages=25.
- **Flexible Turn Control**: You can allow repeated speakers or prevent back-to-back turns with allow_repeated_speaker.

---

### 💡 Why Use It?

This mode is ideal when:
- You need a **clear, single-point answer** (e.g., a domain expert).
- You want to **avoid clutter** from overlapping or redundant replies.
- You're simulating real-life dynamics, where a leader or specialist takes the spotlight.

---

### 🔬 Comparison with Other Modes

| Strategy               | Determinism       | Agent Turn Logic                         | Best For                                       |
|------------------------|-------------------|------------------------------------------|------------------------------------------------|
| [`RoundRobinGroupChat`](https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.teams.html#autogen_agentchat.teams.RoundRobinGroupChat)  | Deterministic     | Fixed circular order                     | Equal participation, structured dialogue, Panel-style debates, brainstorming       |
| [`SelectOneGroupChat`](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/selector-group-chat.html)   | Non-deterministic | LLM selects one agent to respond         | Focused replies, expert selection, Expert Q&A, focused dialog              |

---


```python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import SelectorGroupChat
from autogen_agentchat.conditions import TextMentionTermination

# Load environment variables from .env file
load_dotenv()

azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

print("Endpoint:", azure_openai_endpoint)
print("Model:", azure_openai_model_name)
print("API Version:", azure_openai_api_version)

async def run_ai_agent_debate_stream():
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
        description="A Data Engineer who ingests, cleans, transforms, and stores data in either a data lake or a database.",
        model_client=model_client,
        system_message=(
            "You are a highly skilled Data Engineer responsible for ingesting, cleansing, transforming, and storing structured "
            "and unstructured data. You work with cloud-based data lakes and relational/non-relational databases. When given a "
            "data source or use case, you decide the most appropriate pipeline architecture (batch vs. streaming), apply transformations, "
            "handle schema drift, and ensure scalability. You prioritize performance, security, and reusability. Document assumptions "
            "clearly and suggest improvements where applicable. "
            "kEEP ALL CONVERSATION VERY CONCISE"
            "End with DONE"
        ),
    )

    SQLDeveloper = AssistantAgent(
        name="SQLDeveloper",
        description="An SQL Developer who focuses on creating database objects.",
        model_client=model_client,
        system_message=(
            "You are an experienced SQL Developer responsible for creating efficient, secure, and maintainable database objects. "
            "You write stored procedures, views, tables, indexes, and functions tailored to business logic. You optimize queries for "
            "performance and maintain integrity constraints. You understand schema design, normalization vs. denormalization, and how "
            "to support analytics pipelines. When given requirements, generate precise SQL scripts and explain design choices concisely."
            "kEEP ALL CONVERSATION VERY CONCISE"
            "End with DONE"
        ),
    )

    ReportBuilder = AssistantAgent(
        name="ReportBuilder",
        description="Report Builder focuses on building interactive reports and dashboards.",
        model_client=model_client,
        system_message=(
            "You are an expert Report Builder specializing in developing interactive reports and dashboards using modern BI tools. "
            "You understand data modeling, UX principles, and visual storytelling. Based on business goals, you choose appropriate "
            "visualizations, apply filters and slicers, and optimize performance through techniques like aggregations and DAX expressions. "
            "Tailor outputs to decision-makers, ensure clarity, and suggest improvements to enhance user experience."
            "kEEP ALL CONVERSATION VERY CONCISE"
            "End with DONE"
        ),
    )

    selector_prompt = """
    Based on the agent descriptions and the current context, select the most appropriate agent to handle the task.

    {roles}

    Current conversation context:
    {history}   

    Select ONE agent from {participants} to handle the task.
    The typical task flow is: DataEngineer processes and prepares the data → SQLDeveloper structures and optimizes it → ReportBuilder visualizes it.
    """





    team = SelectorGroupChat(
        participants=[DataEngineer, SQLDeveloper,ReportBuilder],
        model_client=model_client,
        max_turns=5,
        selector_prompt=selector_prompt,
        termination_condition=TextMentionTermination(text="DONE"),
        allow_repeated_speaker=True
    )

    async for message in team.run_stream(task="data ingestion"):
        try:
            print("\n" + "="*60)
            print(f"🗣️ From: {message.source}")
            print("💬 Message:")
            print(message.content)
            print("="*60)
        except AttributeError:
            print("\n" + "="*60)
            print("⚠️ Unstructured message received:")
            print(message)
            print("="*60)





if __name__ == "__main__":
    asyncio.run(run_ai_agent_debate_stream())
```


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
