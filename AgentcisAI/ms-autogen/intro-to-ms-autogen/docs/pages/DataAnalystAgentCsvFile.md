#
<h1 style="color:white; text-align:center;">
Microsoft AutoGen Multi-Agent: <br>
Unleashing the Power of Natural Language for Data Analysis 
</h1>

###  🧠 AI-Powered Data Analysis Agent Assistant Demo

This demo is all about showing how far natural language processing has come, especially in the world of generative AI. Instead of writing complex code or clicking through endless menus, you’ll simply talk to the agent in plain English. The agent will understand your intent, break it down into actionable steps, and carry out the analysis for you.

We’ll hand the agent a single CSV file containing sales data. From there, you’ll see how it can perform advanced analysis like identifying trends, generating visualizations, and answering deep business questions without any manual coding.

Behind the scenes, the system uses Azure OpenAI to interpret your instructions and generate Python code, which runs locally but could also run in a docker container environment to produce insights. It’s a hands-on showcase of how intelligent agents can automate and orchestrate complex tasks, making data exploration faster, smarter, and more intuitive.

Whether you're a data enthusiast or just curious about the future of AI-powered workflows, this demo will give you a glimpse into how multi-agent systems and natural language interfaces are transforming the way we work with data.



#### 📁 `DataAnalysisAgent.py`

This script initializes two agents:  
- 🧠 **AssistantAgent** for generating Python code based on natural language tasks  
- 🤖 **CodeExecutorAgent** for executing the generated code and returning results  

The agents communicate in a round-robin loop, and the workflow terminates automatically when a specific message (`TERMINATE`) is detected.

#### 🛠️ Tasks

1. **Copy and paste** the code into a text editor (e.g., Notepad)  
2. **Save the file** as `DataAnalysisAgent.py`  

> 📌 **Note:** We will use this file later in the demo to orchestrate agent-based data analysis.

```python
# 🌐 Standard Python libraries used for system operations, async tasks, file management, and regex
import os
import asyncio
import shutil
import re

# 🧪 Loads environment variables from a .env file into the Python runtime
from dotenv import load_dotenv

# 🧵 Core utility for controlling task cancellation
from autogen_core import CancellationToken

# 🤝 AI Agent Chat Framework: agent definitions, message exchange, team orchestration, and termination logic
from autogen_agentchat.agents import CodeExecutorAgent, AssistantAgent
from autogen_agentchat.messages import TextMessage
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.base import TaskResult

# ⚡ External integrations for language model access and local command-line code execution
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient  
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor

# 📦 Load environment values (keys, endpoints, model name) from .env file for secure configuration
load_dotenv()

# 🛠️ Retrieve environment configs needed to authenticate with Azure OpenAI service
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

# 🔍 Print loaded configs for verification
print("🔌 Endpoint:", azure_openai_endpoint)
print("🧠 Model:", azure_openai_model_name)
print("📅 API Version:", azure_openai_api_version)

# 👥 Asynchronous setup of AI team agents: AssistantAgent and CodeExecutorAgent
async def initialize_ai_agent_team():
    # 🎯 Configure Azure OpenAI chat client with environment credentials
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    # 💬 AssistantAgent responsible for planning and generating Python code
    Codedeveloper = AssistantAgent(
        name='Codedeveloper',
        model_client=model_client,
        system_message="""
        You are a Data Analysis and Visualization Expert and 
        You will be asked questions related to a dataset

        📂 Dataset:
        - File name: **"bicycle_data_uneven.csv"**
        - Located in the working directory

        Begin with a clear plan to answer the question, then provide Python code in a single code block.
        You are working with a code execution agent:
        - Wait for code execution before continuing.
        - Use `pandas` when applicable.
        - If a required library is missing, use `pip` in a `shell` block.
        - When displaying tabular data, format the output as a readable table

        When creating plots:
        - Use matplotlib for visualization.
        - DO NOT use `.show()` and `print`  under any circumstances.
        - Save plots using `savefig()` as a PNG file in the working directory.
        - After successful execution, print exactly: GENERATED:<filename>
        After providing the final answer, print exactly: `TERMINATE` to end the conversation.
        - After successful execution, print exactly: **GENERATED:<filename>**
        After providing the final answer, print exactly: `TERMINATE` to end the conversation.
        """,
    )


    # 🧪 CodeExecutorAgent executes code provided by the assistant and returns results/output
    local_executor = LocalCommandLineCodeExecutor(work_dir="CodeExecutionEnv")
    code_executor = CodeExecutorAgent(
        name='CodeExecutor',
        code_executor=local_executor,
        system_message="""
        You are a code execution agent.
        Follow these rules:
        - Execute received code as written. Do not modify or interpret its intent.
        - Print any standard output or errors from execution.
        - If the code contains plotting logic with matplotlib, replace `plt.show()` with `plt.show()`.
        - Rely only on `savefig()` to generate charts and save them as PNG files in the working directory.
        - If a chart is saved successfully, print on a new line: `GENERATED:<filename>`
        After successful execution, return all outputs to the AssistantAgent. If you detect `TERMINATE`, end the session.
        Do not engage in planning, explanation, or conversation—just execute and return results.
        """
    )    

    # 🔄 Initialize a round-robin dialog loop between agents with a max turn limit and termination trigger
    team = RoundRobinGroupChat(
        participants=[Codedeveloper, code_executor],
        max_turns=20,
        termination_condition=TextMentionTermination(text="TERMINATE")
    )

    # 🎯 Return initialized team and executor for orchestration
    return team, code_executor

# 🚀 Orchestrates the workflow between agents based on a user-defined task
async def orchestrate_ai_agent_workflow(team, code_executor, task):
    async for msg in team.run_stream(task=task):
        if isinstance(msg, TextMessage):
            # 🗨️ Yield structured chat output from participating agents
            yield f"{msg.source}: {msg.content}"
        elif isinstance(msg, TaskResult):
            # 🛑 Yield final stop reason when task concludes
            yield f"Stop reason: {msg.stop_reason}"
```


#### 📁 `ChatbotApp.py`

This script sets up a chatbot-style web app using **Streamlit**.  
It allows users to describe data tasks in plain language, then displays the live conversation between two AI agents—one that writes Python code and another that runs it.  
The app also shows any generated plots and keeps a running chat history for context.

---

### 🛠️ Tasks

1. **Copy and paste** the code into a text editor (e.g., Notepad)  
2. **Save the file** as `ChatbotApp.py`  
> 📌 **Note:** We'll use this file to launch the chatbot interface and interact with the AI agents through Streamlit.

```python
import streamlit as st
import asyncio
import sys
import re
import os

from DataAnalysisAgent import initialize_ai_agent_team, orchestrate_ai_agent_workflow

# Windows-specific asyncio fix
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

def get_image_file_name(msg):
    match = re.search(r'GENERATED:([^\s]+.png)', msg)
    return match.group(1) if match else None

# App setup
st.set_page_config(page_title="AI Data Assistant", page_icon="🧠")
st.title("🧠 AI Data Task Assistant")

# Initialize chat history
if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

# Render previous messages
for role, msg, avatar in st.session_state.chat_history:
    with st.chat_message(role, avatar=avatar):
        st.markdown(f"##### {msg}")

# Capture user input
user_input = st.chat_input("Describe your task (e.g. Analyze sales.csv and show top regions):")

if user_input:
    task_description = user_input
    st.session_state.chat_history.append(("user", user_input, "🧑‍💻"))
    st.info("Running your task... please wait ⏳")

    async def full_workflow():
        try:
            team, code_executor = await initialize_ai_agent_team()

            async for msg in orchestrate_ai_agent_workflow(team, code_executor, task_description):
                # Determine message role
                if msg.startswith("Codedeveloper"):
                    role, avatar = "ai", "🧠"
                elif msg.startswith("CodeExecutor"):
                    role, avatar = "Executor", "🤖"
                else:
                    role, avatar = "system", "📦"

                st.session_state.chat_history.append((role, msg, avatar))
                with st.chat_message(role, avatar=avatar):
                    st.markdown(f"##### {msg}")

                # Display generated image if available
                if filename := get_image_file_name(msg):
                    image_path = os.path.abspath(os.path.join("CodeExecutionEnv", filename))
                    if os.path.exists(image_path):
                        st.image(image_path, caption=filename)
                    else:
                        st.warning(f"⚠️ Image not found: {image_path}")

            # Final status message
            final_msg = "Analysis complete! ✅"
            st.session_state.chat_history.append(("system", final_msg, "✅"))
            with st.chat_message("system", avatar="✅"):
                st.success(final_msg)

        except Exception as e:
            error_msg = f"An error occurred: {e}"
            st.session_state.chat_history.append(("system", error_msg, "⚠️"))
            with st.chat_message("system", avatar="⚠️"):
                st.error(error_msg)

    asyncio.run(full_workflow())
```
3. **go to** your vitual python activated environment
4. **Run** `streamlit <<run your directory>>\ChatbotApp.py`

<div style="display: flex; justify-content: space-between;">
  <a href="DirectAgentDynamicInteractionSelect.md">← Previous Page</a>
  <a href="DataAnalystAgentCsvFile.md">Next → Page</a>
</div>
