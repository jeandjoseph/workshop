#
<h2 style="color:white; text-align:center;">
Coordinating SQL Creation, Execution, and Reporting with AutoGen 0.4+
</h2>
This demo showcases how to build an end-to-end data engineering workflow using Microsoft AutoGen’s multi-agent framework. By assigning distinct roles to specialized agents such as SQL script generation, saving, execution, and status reporting we demonstrate how complex tasks can be modularized and automated through intelligent agent coordination.


The goal is to highlight practical use of AutoGen 0.4+ features like SelectorGroupChat and MagneticOneGroupChat to manage task delegation and execution flow. This setup not only improves scalability and maintainability but also illustrates how multi-agent systems can streamline data operations in real-world scenarios.

<br>

This demo centers on using SelectorGroupChat to intelligently coordinate agent interactions, ensuring each task is routed to the agent best suited for its role and context. For a deeper dive into team-based chat strategies, feel free to explore the [Team GroupChat documentation](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/index.html).


```python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent, CodeExecutorAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor


class AgenticTeamInitializer:
    """
    Encapsulates the initialization logic for a team of assistant and executor agents
    using Azure OpenAI and AutoGen AgentChat SDK.
    """

    def __init__(self):
        # Load environment variables from .env
        load_dotenv()

        # Azure OpenAI configuration
        self.azure_openai_model_name = os.getenv("MODEL")
        self.azure_openai_api_key = os.getenv("API_KEY")
        self.azure_openai_endpoint = os.getenv("BASE_URL")
        self.azure_openai_api_version = os.getenv("API_VERSION")

        # Optional debug output
        print("Endpoint:", self.azure_openai_endpoint)
        print("Model:", self.azure_openai_model_name)
        print("API Version:", self.azure_openai_api_version)

        # Initialize chat completion client
        self.model_client = AzureOpenAIChatCompletionClient(
            azure_deployment=self.azure_openai_model_name,
            azure_endpoint=self.azure_openai_endpoint,
            model=self.azure_openai_model_name,
            api_version=self.azure_openai_api_version,
            api_key=self.azure_openai_api_key
        )

    async def initialize_team(self, user_message: str):
        """
        Constructs and returns a RoundRobinGroupChat team and executor agent.
        """

        # Agent that creates T-SQL from schema definition
        DbCodeCreator = AssistantAgent(
        name="DbCodeCreator",
        description="Generates T-SQL scripts for SQL Server from CSV schema.",
        model_client=self.model_client,
        #handoffs=["PythonCodeCreator"],
        system_message="""
        You are a T-SQL Developer collaborating with 'PythonCodeCreator'.

        Your task:
        - Generate T-SQL scripts to:
        1. Create SQL Server schema objects.
        2. Import a CSV file with headers into the appropriate table.

        Schema definition:
        ProductId INT, ProductName VARCHAR(50), ProductType VARCHAR(30), Color VARCHAR(15),
        OrderQuantity INT, Size VARCHAR(15), Category VARCHAR(15), Country VARCHAR(30),
        Date DATE, PurchasePrice DECIMAL(18,2), SellingPrice DECIMAL(18,2)

        Response format:
        - Always reply with **only one** markdown block containing the SQL code:
        ```sql
        -- your code here

        - Do NOT add explanations, commentary, or multiple code blocks.

        After 'CodeSavor' confirms successful execution, respond with: `TERMINATE`
        """            
        )

        # Agent that writes the T-SQL script into Python code
        PythonCodeCreator = AssistantAgent(
        name="PythonCodeCreator",
        description="Generates Python code to save T-SQL scripts into files without executing them.",
        model_client=self.model_client,
        #handoffs=["CodeSavor"],
        system_message="""
        You are a Python Developer collaborating with 'DbCodeCreator'.

        Your responsibilities are:
        1. Write a Python script that:
            - Accepts a list of T-SQL scripts, each represented as a dictionary with keys like `name` and `content`.
            - Saves each script into a separate `.sql` file in the working directory.
            - Uses the `name` field to generate the filename (e.g., `name.sql`). If `name` is missing, use a fallback like `script_1.sql`, `script_2.sql`, etc.
            - At the END of your codes Confirm that all `.sql` files have been saved successfully.
        2. Follow these strict formatting rules:
        - Do NOT execute any code.
        - Respond with a single Python code block formatted in markdown:
            ```python
            # your code here
            ```
        - Do NOT include explanations, comments, or multiple code blocks.

        3. After generating the Python script:
        - Initiate handoff to `CodeSavor` for execution.

        """
        )

        # Agent that runs Python code and saves scripts
        CodeSavor = CodeExecutorAgent(
        name="CodeSavor",
        code_executor=LocalCommandLineCodeExecutor(work_dir="CodeExecutionEnv"),
        system_message="""
        You are a Code Executor.

        Responsibilities:
        - Execute Python code received from 'PythonCodeCreator' inside the working directory.
        - Save each T-SQL code block to a unique `.sql` file.
        - **DO NOT REPLY ON ANY OUTPUT**.
        
        - After executing Python code successfully, respond with `TERMINATE`.
        - Do NOT re-execute the same code. If code has already been run, respond with `TERMINATE`.

        """
        )

        # Termination logic for the team
        termination = TextMentionTermination("TERMINATE") | MaxMessageTermination(max_messages=5)

        # Instantiate round-robin group chat
        team = RoundRobinGroupChat(
            participants=[DbCodeCreator, PythonCodeCreator, CodeSavor],
            termination_condition=termination
        )

        return team, CodeSavor



```





