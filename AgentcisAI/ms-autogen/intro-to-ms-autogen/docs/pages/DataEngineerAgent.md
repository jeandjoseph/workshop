#
<h1 style="color:white; text-align:center;">
Microsoft AutoGen Multi-Agent: <br>
Coordinating SQL Creation, Execution, and Reporting with AutoGen 0.4+
</h1>
This demo showcases how to build an end-to-end data engineering workflow using Microsoft AutoGen’s multi-agent framework. By assigning distinct roles to specialized agents—such as SQL script generation, saving, execution, and status reporting—we demonstrate how complex tasks can be modularized and automated through intelligent agent coordination.

<br>

The goal is to highlight practical use of AutoGen 0.4+ features like SelectorGroupChat and MagneticOneGroupChat to manage task delegation and execution flow. This setup not only improves scalability and maintainability but also illustrates how multi-agent systems can streamline data operations in real-world scenarios.

This demo centers on using SelectorGroupChat to intelligently coordinate agent interactions, ensuring each task is routed to the agent best suited for its role and context. For a deeper dive into team-based chat strategies, feel free to explore the [Team GroupChat documentation](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/index.html).


```python
import os
import re
import asyncio
from dotenv import load_dotenv

from autogen_agentchat.agents import CodeExecutorAgent, AssistantAgent
from autogen_agentchat.teams import SelectorGroupChat
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_agentchat.messages import TextMessage
from autogen_agentchat.base import TaskResult

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor

# Load environment variables
load_dotenv()
azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_version = os.getenv("API_VERSION")

assert all([azure_openai_model_name, azure_openai_api_key, azure_openai_endpoint, azure_openai_api_version]), \
    "Missing Azure OpenAI configuration in .env file"

# Define paths and credentials
sql_script_files_dir = "sql_scripts"
csv_file_path = "bicycle_data.csv"
csv_error_log = "error_log.csv"
stage_table_name = "BicycleStage"
sql_server_name = "localhost"
sql_database_name = "AgenticAI"
authentication_mode = "windows authentication"

os.makedirs(sql_script_files_dir, exist_ok=True)

# Agent team initialization
async def initialize_ai_agent_team():
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=azure_openai_model_name,
        azure_endpoint=azure_openai_endpoint,
        model=azure_openai_model_name,
        api_version=azure_openai_api_version,
        api_key=azure_openai_api_key,
    )

    DbCodeCreator = AssistantAgent(
        name="DbCodeCreator",
        description="Generates T-SQL scripts for SQL Server from CSV schema.",
        model_client=model_client,
        system_message="""
        Act as a T-SQL Developer expert. Write scripts to create database schemas and import a CSV with headers into SQL Server.
        Once 'CodeSavor' notified you that his done, please respond "TERMINATE" 
        Schema:
        ProductId INT, ProductName VARCHAR(50), ProductType VARCHAR(30), Color VARCHAR(15),
        OrderQuantity INT, Size VARCHAR(15), Category VARCHAR(15), Country VARCHAR(30),
        Date DATE, PurchasePrice DECIMAL(18,2), SellingPrice DECIMAL(18,2)
        Respond with SQL code inside a single markdown block.
        """
    )

    PythonCodeCreator = AssistantAgent(
        name="PythonCodeCreator",
        description="Saves SQL code received and passes to execution agent.",
        model_client=model_client,
        system_message=f"""
        Act as a Python Developer. Save T-SQL scripts from 'DbCodeCreator' into files under '{sql_script_files_dir}'.
        Respond with Python code inside a single markdown block.
        """
    )

    CodeSavor = CodeExecutorAgent(
        name="CodeSavor",
        code_executor=LocalCommandLineCodeExecutor(work_dir="CodeExecutionEnv"),
        system_message="""
        Execute Python code from 'PythonCodeCreator' in the working directory.
        Make sure each T-SQL code block save in a separate <filename.sql>
        No need to return any *OUTPUT** if The POSIX exit code was: 0
        Notify 'DbCodeCreator' that all scripts have been saved
        End with: "TERMINATE"
        """
    )

    termination = TextMentionTermination("TERMINATE") | MaxMessageTermination(max_messages=10)

    selector_prompt = """
    Select the next agent to respond.
    {roles}
    Context:   
    - DbCodeCreator: Generates T-SQL scripts for SQL Server from CSV schema.
    - PythonCodeCreator: Saves SQL code received and passes to execution agent.
    - CodeSavor: Execute Python code from 'PythonCodeCreator' to save in the working directory.
    {history}
    Agents must end with TERMINATE before the process is allowed to finish.
    """

    team = SelectorGroupChat(
        participants=[DbCodeCreator, PythonCodeCreator, CodeSavor],
        model_client=model_client,
        termination_condition=termination,
        selector_prompt=selector_prompt,
        allow_repeated_speaker=False
    )

    return team, CodeSavor

# Define initial task
task = """
1. Generate T-SQL script to create schema 'stg' if not exists.
2. Generate T-SQL script to create schema 'prd' if not exists.
3. Generate T-SQL script to create schema 'etl_process' if not exists.
"""

# Orchestration logic
async def orchestrate_ai_agent_workflow(team, executor_agent, task):
    async for msg in team.run_stream(task=task):
        if isinstance(msg, TextMessage):
            cleaned_content = re.sub(r'^#{1,6}\s*', '', msg.content)
            print(f"{msg.source}: {cleaned_content.strip()}")
        elif isinstance(msg, TaskResult):
            print(f"Stop reason: {msg.stop_reason}")

# Entrypoint
async def main():
    team, executor_agent = await initialize_ai_agent_team()
    await orchestrate_ai_agent_workflow(team, executor_agent, task)

# Launch
asyncio.run(main())
```