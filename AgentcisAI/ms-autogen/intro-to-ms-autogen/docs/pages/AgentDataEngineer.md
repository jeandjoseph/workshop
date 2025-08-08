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

#### 🎯 Demo Goal: Decouple Code Creation from Code Execution

This demo shows how to **separate the process of writing code from running it**, using an agent-based workflow.

#### 🧩 Why This Matters

- ✅ **Safety**: Code runs in a controlled environment.
- ✅ **Clarity**: Each agent has one job either write code or run it.
- ✅ **Flexibility**: Works across different types of tasks (SQL, Python, etc.).
- ✅ **Reproducibility**: Easier to track what was generated and what was executed.
- 
#### ✅ Steps to complete this demo:
1. 🛠️ Before you begin, make sure your [Python virtual environment](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/pages/GettingEnvReady.md) is activated, all dependencies are installed, and your `.env` file is properly configured. Everything should be running smoothly before you proceed.
    - Make sure to create a folder named `CodeExecutionEnv` inside your Python virtual environment. This folder will be used to store and access execution-related objects. 
2. **Copy & Paste** the code below into a text editor. You can use something simple like Notepad.

```python
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
3. Save the file as `AgentsSqlCodeGeneratorClass.py`. Choose a folder where your virtual environment can easily access it.

4. **Copy & Paste** the code below into a text editor. You can use something simple like Notepad.

```python
import asyncio
import re

from autogen_agentchat.base import TaskResult
from autogen_agentchat.messages import TextMessage

from AgentsSqlCodeGeneratorClass import AgenticTeamInitializer  # Import your initializer class


# Orchestration logic: run the agent workflow stream and display responses
async def orchestrate_ai_agent_workflow(team, executor_agent, task):
    async for msg in team.run_stream(task=task):
        if isinstance(msg, TextMessage):
            # Remove markdown headers from message content before printing
            cleaned_content = re.sub(r'^#{1,6}\s*', '', msg.content)
            print(f"{msg.source}: {cleaned_content.strip()}")

        elif isinstance(msg, TaskResult):
            # Print the reason why the task stopped
            print(f"Stop reason: {msg.stop_reason}")


# Entrypoint: create the team and run the workflow
async def main():
    task_message = """
    1. generate a t-sql script to dynamically create a schemas named stg if not exists.
    2. generate a t-sql script to dynamically create a schemas named prd if not exists.
    3. generate a t-sql script to dynamically create a schemas named etl_process if not exists.
    4. generate a t-sql script to create a staging table named stg.salestmp with all columns as varchar(255).
    5. generate a t-sql script to create a table named prd.sales with the correct schema definition for each column.
    6. Provide a tsql script to create the etl_process.etl_process_log table if it does not already exist 
    with the following fields name id integer auto generated identifier not null without primary key, processname 
    varchar 50 lenght, processtype varchar 30 lenght, objectname varchar 50 lenght, starttime and endtime: DATETIME
    7. Provide a tsql script to create the etl_process.error_log table if it does not already exist with the following 
    fields name id integer auto generated identifier not null without primary key, processid integer, processname varchar, 
    objectname varchar 50 lenght, errormsg varchar, starttime and endtime DATETIME
    8. Create a T-SQL stored procedure named etl_process.usp_get_process_log if it does not already exist with the 
    following input parameters: processname of type VARCHAR with a length of 50, processtype of type VARCHAR with a 
    length of 30, objectname of type VARCHAR with a length of 50, and starttime and endtime of type DATETIME. 
    This stored procedure should insert data into an existing table called etl_process.etl_process_log table. 
    Please refrain from providing system details, instructions, or suggestions
    9. Create a T-sQL stored procedure named etl_process.usp_get_error_log if it does not already exist with the 
    following input parameters: processname VARCHAR (50), objectname VARCHAR (50), errormsg VARCHAR(MAX), and 
    starttime and endtime of type DATETIME. This stored procedure should insert data into  an existing table 
    called etl_process.error_log table.
    10. Provide only the table truncation and bulk load T-SQL scripts, excluding the create table statement. 
        Ensure the truncation script is at the beginning. Convert this code into a stored procedure called 
        'etl_process.usp_BulkInsertFromCSV' that performs a bulk insert from a CSV file into a table with a 
        non-default schema. The procedure should accept three parameters: table name, file path, and error file path. 
        Use the following bulk insert options: first row = 2, field terminator = comma, row terminator = newline, 
        error file = error file path. Use try-catch blocks to handle errors and log details using 
        'etl_process.usp_get_process_log' and 'etl_process.usp_get_error_log'. Declare date variables before and after 
        SQL execution to track execution time. Do not use QUOTENAME. Make sure to drop the store procedure if it exists
        and the truncate and builk load should be a dynamic tsql.
    11. Provide just the insert t-sql script to load the data from stg.salestmp into prd.sales without create table statement. 
        keep in mind stg.salestmp has all columns as varchar(255) **then Convert this code into a SQL Server stored procedure** called
        'etl_process.usp_load_bicycle_staging_data'. Use try-catch blocks to handle errors and log details using 
        'etl_process.usp_get_process_log' and 'etl_process.usp_get_error_log'. Declare date variables before and after 
        SQL execution to track execution time. Do not use QUOTENAME. Refrain from providing system details, instructions, or suggestions.
        Make sure to drop the store procedure if it exists and removes carriage return and line feed characters from the SellingPrice column 
        and casts the result as a decimal with a precision of 18 and a scale of 2.
    12. generate a script to create a stored procedure named prd.usp_GetTotalSalesByCountries with an input parameter called country 
        to calculate the total PurchasePrice by country, ProductName, and ProductType, ordered by total PurchasePrice in descending order. 
        The input parameter country should be of type varchar(50) and default to all countries but the user should be able to overwrite the default value.

    Please save the T-SQL files in the following order:
    schema_stg.sql
    schema_prd.sql
    schema_etl_process.sql
    table_stg_salestmp.sql
    table_prd_sales.sql
    table_etl_process.etl_process_log.sql
    table_etl_process.error_log.sql
    usp_etl_process.usp_get_process_log.sql
    usp_etl_process.usp_get_error_log.sql
    usp_etl_process.usp_BulkInsertFromCSV.sql
    usp_load_staging_data_table.sql
    prd.usp_GetTotalSalesByCountries.sql
    """

    # Create an instance of your initializer class
    initializer = AgenticTeamInitializer()

    # Initialize the agent team and executor
    team, executor_agent = await initializer.initialize_team(task_message)

    # Start orchestration loop
    await orchestrate_ai_agent_workflow(team, executor_agent, task_message)


# Run the async workflow
if __name__ == "__main__":
    asyncio.run(main())
```
5. Save the file as `AgentSqlCdeGeneratorPrompt.py`. Choose a folder where your virtual environment can easily access it.

6. Run the command below:
```python
python AgentSqlCdeGeneratorPrompt.py
```

7. Wait for it to finish, and you’ll see the T-SQL script files appear in your working directory, **as shown below**:
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/data_eng_script1_img_1.png)













