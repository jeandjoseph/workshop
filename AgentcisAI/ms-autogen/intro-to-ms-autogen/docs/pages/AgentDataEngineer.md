#
<h2 style="color:white; text-align:center;">
Coordinating SQL Creation, Execution, and Reporting with AutoGen 0.4+
</h2>
In traditional data engineering and analytics, success hinges not just on technical execution but on the clarity of business expectations. When knowledge transfer is fragmented, when project goals, schema definitions, or operational constraints are siloed, human teams struggle to deliver as expected. Agentic AI flips this paradigm: by embedding business logic directly into system messages and orchestrating agents with clear roles, we can simulate the precision of a well-informed human team.

<br>

This demo shows how AutoGen’s AgentChat framework enables a round-robin group of agents to collaboratively perform end-to-end database development from schema interpretation to SQL generation, Python packaging, and file execution and all within a Microsoft Autogen Teams style chat loop.

#### 🧩 The Agentic Cast
Using AutoGen’s AgentChat SDK, we define three specialized agents:

| **Agent Name**      | **Role Description**                                                                 |
|---------------------|--------------------------------------------------------------------------------------|
| `DbCodeCreator`     | Converts schema definitions into T-SQL scripts for SQL Server                        |
| `PythonCodeCreator` | Wraps T-SQL scripts into Python code that saves them as `.sql` files                 |
| `CodeSavor`         | Executes Python code to persist the SQL scripts locally                              |

Each agent is initialized with a precise system message that encodes its responsibilities and collaboration logic. This is where the magic happens: the system message acts as a proxy for human intent, guiding the agent to behave as if it were a domain expert.

#### 🔁 Round-Robin Chat: Simulating Human Collaboration
The agents are orchestrated using `RoundRobinGroupChat`, a built-in AutoGen construct that mimics structured turn-taking. This ensures that each agent contributes in sequence, handing off tasks and terminating when complete.

Termination is governed by:
- `TextMentionTermination("TERMINATE")`: Agents stop when they see the keyword.
- `MaxMessageTermination(5)`: A safety net to prevent infinite loops.
- `LocalCommandLineCodeExecutor`: For demo purposes, this agent runs shell commands directly in your local environment. In real-world setups, it's best to sandbox execution inside a [Docker container](https://microsoft.github.io/autogen/stable/reference/python/autogen_ext.code_executors.docker.html#module-autogen_ext.code_executors.docker) for safety and reproducibility. |

#### 💡 Why Knowledge Transfer Matters
The most important takeaway? Agentic success depends on how well human expectations are encoded into system messages. If you want your agents to perform like humans, you must guide them like humans through clear, contextual instructions.

Prompt optimization is always a work in progress, but the foundation is business knowledge. Whether you're defining a schema, specifying output formats, or setting termination logic, the agent’s effectiveness is directly proportional to the clarity of your




```python
import os
import asyncio
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent, CodeExecutorAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor


class CodeDeveloperTeamBuilder:
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

import os
import pyodbc
import asyncio
import logging
import re
from typing import List, Any
from dotenv import load_dotenv

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_agentchat.agents import AssistantAgent, CodeExecutorAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination, MaxMessageTermination
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor
from autogen_agentchat.base import TaskResult
from autogen_agentchat.messages import TextMessage
from autogen_core.tools import FunctionTool

logging.basicConfig(level=logging.WARNING)

class CodeDeveloperTeamExecutor:
    """
    Encapsulates the initialization logic for a team of assistant and executor agents
    using Azure OpenAI and AutoGen AgentChat SDK.
    """

    def __init__(self):
        try:
            # Load environment variables from .env
            load_dotenv()

            # Required environment variables
            required_vars = [
                "MODEL", "API_KEY", "BASE_URL", "API_VERSION",
                "sql_svr_name", "sql_db_name", "sql_stage_table_name",
                "csv_file_dir", "csv_file_error_dir", "authentication_mode", "sql_script_dir"
            ]
            for var in required_vars:
                if not os.getenv(var):
                    raise ValueError(f"Missing required environment variable: {var}")

            # Azure OpenAI configuration
            self.azure_openai_model_name = os.getenv("MODEL")
            self.azure_openai_api_key = os.getenv("API_KEY")
            self.azure_openai_endpoint = os.getenv("BASE_URL")
            self.azure_openai_api_version = os.getenv("API_VERSION")
            self.sql_svr_name = os.getenv("sql_svr_name")
            self.sql_db_name = os.getenv("sql_db_name") 
            self.sql_stage_table_name = os.getenv("sql_stage_table_name")  
            self.csv_file_dir = os.getenv("csv_file_dir")
            self.csv_file_error_dir = os.getenv("csv_file_error_dir")
            self.authentication_mode = os.getenv("authentication_mode")
            self.sql_script_dir = os.getenv("sql_script_dir")    

            # Initialize chat completion client
            self.model_client = AzureOpenAIChatCompletionClient(
                azure_deployment=self.azure_openai_model_name,
                azure_endpoint=self.azure_openai_endpoint,
                model=self.azure_openai_model_name,
                api_version=self.azure_openai_api_version,
                api_key=self.azure_openai_api_key
            )

            # Register the SQL execution tool
            self.run_tsql_scripts = FunctionTool(
                func=self.execute_tsql_from_path_or_text,
                name="run_sql_folder_tool",
                description=(
                    "Executes SQL scripts from a folder, a single .sql file, or a raw SQL string "
                    "on the specified SQL Server and database using Windows Authentication. "
                    "Handles 'GO' batch separators and returns results from each script or query."
                ),
                strict=True
            )

        except Exception as e:
            logging.error(f"Initialization failed: {e}")
            raise

    def execute_tsql_from_path_or_text(self, input_path: str, server: str, database: str) -> List[dict]:
        """
        Runs SQL scripts from a file or folder on a SQL Server database.
        Supports 'GO' batch separators and returns results per script.

        Args:
            input_path: Path to a .sql file or folder containing .sql files.
            server: SQL Server name.
            database: Target database name.

        Returns:
            List of dictionaries with script path and execution results.
        """
        conn_str = (
            r'DRIVER={ODBC Driver 17 for SQL Server};'
            fr'SERVER={server};'
            fr'DATABASE={database};'
            r'Trusted_Connection=yes;'
        )

        def run_batches(sql_text: str) -> List[Any]:
            conn = pyodbc.connect(conn_str)
            cursor = conn.cursor()
            batches = re.split(r'^\s*GO\s*$', sql_text, flags=re.IGNORECASE | re.MULTILINE)
            results = []

            for batch in batches:
                batch = batch.strip()
                if not batch:
                    continue
                try:
                    cursor.execute(batch)
                    try:
                        results.extend(cursor.fetchall())
                    except pyodbc.ProgrammingError:
                        pass  # No results to fetch
                    conn.commit()
                except Exception as e:
                    results.append(f"Error: {str(e)}")

            conn.close()
            return results

        def collect_sql_files(path: str) -> List[str]:
            if os.path.isfile(path) and path.lower().endswith('.sql'):
                return [path]
            elif os.path.isdir(path):
                return [
                    os.path.join(root, file)
                    for root, _, files in os.walk(path)
                    for file in files if file.lower().endswith('.sql')
                ]
            return []

        all_results = []

        if input_path.lower().endswith('.sql') or os.path.isdir(input_path):
            for file_path in collect_sql_files(input_path):
                with open(file_path, 'r', encoding='utf-8') as f:
                    sql = f.read()
                    result = run_batches(sql)
                    all_results.append({file_path: result})
        else:
            result = run_batches(input_path)
            all_results.append({"raw_sql": result})

        return all_results

    async def build_code_executor_team(self, user_message: str):
        """
        Constructs and runs a RoundRobinGroupChat team and executor agent.
        """

        DbScriptExecutor = AssistantAgent(
            name="DbScriptExecutor",
            description="Generates Python code that uses the registered AutoGen tool to prepare SQL Server script execution.",
            model_client=self.model_client,
            tools=[self.run_tsql_scripts],
            system_message="""
            You are a Python Developer collaborating with 'code_executor_agent'.

            Your responsibilities are:
            1. Generate a Python script that:
                - Uses the registered AutoGen tool `run_tsql_scripts` to prepare execution of SQL Server scripts.
                - Accepts either:
                    a) A folder path containing .sql files,
                    b) A single .sql file path,
                    c) A raw T-SQL string.
                - Calls the tool with parameters: `folder_path`, `server_name`, and `database_name`.
                - Does NOT execute the SQL scripts directly.
                - Returns a message confirming that the scripts are ready for execution.

            2. Follow these strict formatting rules:
                - Respond with a single Python code block formatted in markdown:
                    ```python
                    # your code here
                    ```
                - Do NOT include explanations, comments, or multiple code blocks.
                - Do NOT execute any code.

            3. After generating the Python script:
                - Initiate handoff to `code_executor_agent` for execution.
            """
        )

        code_executor_agent = CodeExecutorAgent(
            name="code_executor_agent",
            code_executor=LocalCommandLineCodeExecutor(work_dir="CodeExecutionEnv"),
            system_message="""
            You are a Python Code Executor.

            Responsibilities:
            - Execute Python code received from 'DbScriptExecutor' inside the working directory.
            - Save each T-SQL code block to a unique `.sql` file.
            - Suppress all output if the process completes successfully (exit code 0).
            
            After all tasks are done, wait until you get 'All scripts executed successfully' 
            then notify 'DbScriptExecutor' by responding with: TERMINATE
            """
        )

        termination = TextMentionTermination("TERMINATE") | MaxMessageTermination(max_messages=10)

        team = RoundRobinGroupChat(
            participants=[DbScriptExecutor, code_executor_agent],
            termination_condition=termination
        )
        return team
```










