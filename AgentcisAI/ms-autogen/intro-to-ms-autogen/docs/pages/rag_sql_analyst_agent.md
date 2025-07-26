## Agentic SQL RAG Analyst: A Multi-Agent Orchestration Demo
Welcome to the **Agentic SQL RAG Analyst** demo, your gateway into orchestrating intelligent, multi-agent collaboration using Microsoft AutoGen 0.4+. This walkthrough showcases how to design an end-to-end agentic pipeline that retrieves structured sales data from SQL Server, enhances it through analytical reasoning, and transforms it into compelling visual insights. 

You’ll see how retrieval-augmented generation (RAG) principles are adapted to SQL workflows, where agents coordinate through clearly defined roles: fetching facts, computing business metrics, and rendering professional-grade charts. By the end, you’ll understand how to build reproducible, asynchronous multi-agent systems that are scalable, demo-ready, and deeply modular—all with the latest AutoGen best practices.

When working with sensitive application data—especially inside an organization—it's crucial to draw a hard line between what agents can do and what they must not. AutoGen makes it easy to design powerful autonomous agents, but autonomy without guardrails invites risk.

That's why one of the most important best practices is to externally create tools and explicitly assign them to agents, rather than letting agents invent capabilities on their own. By decoupling agent behavior from orchestration logic, you define clear operational boundaries. This means:
- Agents only access what they’re permitted to
- Sensitive data stays protected behind vetted tool interfaces
- Each agent's role remains scoped, auditable, and testable

You’re not just making things modular—you’re protecting your data, your users, and your organizational integrity. In high-stakes environments, controlled capability is the foundation of responsible agentic design.

🛠️ **Why You Should Pre-Create and Assign Tools**
- 🔒 **Control & Security**: When you define the tool, you control what it does, what it accesses, and how it handles data. If an agent could create tools dynamically, you'd risk unexpected behavior or unclear boundaries.
- 🧩 **Modularity**: Prebuilt tools are reusable, testable, and versioned independently. You can validate a FunctionTool, swap it, or share it across agents just like components in a microservice architecture.
- 📚 **Auditability**: When tools are constructed declaratively (in code) and injected into agents, you maintain a clean provenance of who can do what, using which tool, and for what purpose. That's crucial for debugging, education, and compliance.
- 🚦**Agent Behavior Shaping**: Tools + system messages define the sandbox in which agents operate. Without them, agents would need to infer behavior or generate logic which leads to ambiguity or hallucinated APIs.

**Now let us focus on the demo:**

In this demo, we took a security-first approach to agent design by explicitly limiting what the agent can autonomously retrieve from the database. Rather than granting broad query access, we defined a SQL Server stored procedure **sales.usp_get_sales_summary_by_country** as shown below which returns only the aggregated sales data grouped by product and country. This ensures that the agent never sees raw transactional records or sensitive internal metrics beyond what’s operationally necessary.

📌 Note: Before running this demo, ensure you've downloaded the CSV [file](https://github.com/jeandjoseph/workshop/blob/main/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/csv/bicycle_data.csv) and imported it into a database engine of your choice. For demonstration purposes, we’ll be using SQL Server, which you can [download here](https://www.microsoft.com/en-us/sql-server/sql-server-downloads). Also Before running the demo, make sure to create the following stored procedure in your SQL Server database.

```sql
CREATE PROC sales.usp_get_sales_summary_by_country
AS
BEGIN
    SELECT 
        [ProductName],
        [Country],
        MAX([OrderQuantity]) AS MaxOrderQuantity,
        SUM([PurchasePrice]) AS TotalPurchasePrice,
        SUM([SellingPrice]) AS TotalSellingPrice
    FROM [AgenticAI].[dbo].[bicycle_data_uneven]
    GROUP BY [ProductName], [Country]
END
```

To interface with this controlled data layer, we created an asynchronous Python function **get_sales_summary_by_country_async()** that securely calls the procedure using Windows Authentication. This function is then wrapped as a FunctionTool, annotated for schema clarity, and registered directly to the agent. The agent doesn’t write SQL or choose its own access patterns—it’s only allowed to invoke this tool under guided supervision.

```pytho
# Asynchronous function to fetch pre-aggregated sales data via stored procedure
async def get_sales_summary_by_country_async() -> List[Dict[str, Any]]:
    """
    Asynchronously calls the stored procedure sales.usp_get_sales_summary_by_country
    using Windows Authentication and returns the result as a list of dictionaries.

    This stored procedure encapsulates the aggregation logic—limiting agent access
    to only summary-level bicycle sales data grouped by product and country.
    """

    # Define connection string using Windows Authentication
    conn_str = (
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=localhost;"  # Update this with your actual SQL Server host
        "Database=AgenticAI;"
        "Trusted_Connection=yes;"  # Secure connection without explicit credentials
    )

    # Open database connection using aioodbc and autocommit mode
    async with aioodbc.connect(dsn=conn_str, autocommit=True) as conn:
        # Create a cursor to execute the stored procedure
        async with conn.cursor() as cur:
            # Invoke stored procedure that returns summary sales data
            await cur.execute("EXEC sales.usp_get_sales_summary_by_country")

            # Extract column headers from result metadata
            columns = [column[0] for column in cur.description]

            # Fetch all rows from the result set
            rows = await cur.fetchall()

            # Convert each row into a dictionary keyed by column name
            result = [dict(zip(columns, row)) for row in rows]

            # Return list of result dictionaries to calling agent or tool
            return result


# Register the above function as a tool callable by agent
bicycle_sales_tool = FunctionTool(
    func=get_sales_summary_by_country_async,
    name="get_sales_summary_by_country",
    description=(
        "Retrieves a summary of bicycle sales grouped by product and country "
        "from the AgenticAI SQL Server database using Windows Authentication. "
        "Returns maximum order quantity, total purchase price, and total selling price per product-country pair."
    ),
    strict=True  # Optional: Enforces input/output schema validation for safer agent use
)
```
Why this matters: Again, In organizational environments, especially when working with proprietary or sensitive datasets, it's essential to restrict agent capabilities through predefined tooling. By designing tools externally and assigning them explicitly, we ensure clear governance, enforce scope boundaries, and prevent accidental overreach. Agents operate within the sandbox—we define the edges.

Find the 
```python
# -------------------------------
# 📦 Standard Library
# -------------------------------

import os
from pathlib import Path
import asyncio
from typing import List, Dict, Any
from dotenv import load_dotenv

# -------------------------------
# 🧠 AutoGen Core & AgentChat
# -------------------------------

from autogen_core import CancellationToken
from autogen_core.tools import FunctionTool
from autogen_agentchat.agents import UserProxyAgent, AssistantAgent, CodeExecutorAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.ui import Console
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.base import TaskResult
from autogen_agentchat.messages import BaseMessage
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor

# -------------------------------
# 🔗 External Models & Tools
# -------------------------------

from autogen_ext.models.openai import AzureOpenAIChatCompletionClient

# -------------------------------
# 🔧 Load environment variables
# -------------------------------

load_dotenv()

azure_openai_model_name = os.getenv("MODEL")
azure_openai_api_key = os.getenv("API_KEY")
azure_openai_endpoint = os.getenv("BASE_URL")
azure_openai_api_type = os.getenv("API_TYPE")
azure_openai_api_version = os.getenv("API_VERSION")

print("🔌 Endpoint:", azure_openai_endpoint)
print("🧠 Model:", azure_openai_model_name)
print("📅 API Version:", azure_openai_api_version)


# -------------------------------
# 🔧 Define SQL Server Tool
# -------------------------------

import aioodbc

# Asynchronous function to fetch pre-aggregated sales data via stored procedure
async def get_sales_summary_by_country_async() -> List[Dict[str, Any]]:
    """
    Asynchronously calls the stored procedure sales.usp_get_sales_summary_by_country
    using Windows Authentication and returns the result as a list of dictionaries.

    This stored procedure encapsulates the aggregation logic—limiting agent access
    to only summary-level bicycle sales data grouped by product and country.
    """
    conn_str = (
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=localhost;"  # Update this with your actual SQL Server host
        "Database=AgenticAI;"
        "Trusted_Connection=yes;"
    )

    async with aioodbc.connect(dsn=conn_str, autocommit=True) as conn:
        async with conn.cursor() as cur:
            await cur.execute("EXEC sales.usp_get_sales_summary_by_country")
            columns = [column[0] for column in cur.description]
            rows = await cur.fetchall()
            result = [dict(zip(columns, row)) for row in rows]
            return result

# Register the above function as a tool callable by agent
bicycle_sales_tool = FunctionTool(
    func=get_sales_summary_by_country_async,
    name="get_sales_summary_by_country",
    description=(
        "Retrieves a summary of bicycle sales grouped by product and country "
        "from the AgenticAI SQL Server database using Windows Authentication. "
        "Returns maximum order quantity, total purchase price, and total selling price per product-country pair."
    ),
    strict=True  # Ensures tool calls match expected input/output types
)

# -------------------------------
# 🚀 Initialize Agents and Team
# -------------------------------

async def initialize_ai_agent_team():
    """
    Sets up the multi-agent pipeline and runs a sample sales query.
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

    # 🤖 Assistant agent that retrieves sales data via FunctionTool
    get_sales_data = AssistantAgent(
        name="get_sales_data",
        model_client=model_client,
        tools=[bicycle_sales_tool],
        system_message="""
        You are a data assistant responsible for retrieving bicycle sales data from the AgenticAI SQL Server database.

        Your task:
        - Use the provided tool to call the stored procedure `sales.usp_get_sales_summary_by_country`.
        - Return the raw product-level sales data grouped by country.
        - Do not perform any analysis or interpretation.
        - Hand off the retrieved data to the `sales_analyst` agent for further analysis.

        The data should include:
        - Order quantities
        - Purchase prices
        - Selling prices
        - Any other relevant fields from the database

        Keep your response clear and structured so the analyst can easily interpret it.
        """    
    )

    # 📊 Analyst agent that provides insights and recommendations
    sales_analyst = AssistantAgent(
        name="sales_analyst",
        model_client=model_client,
        system_message="""
        You are a sales data analyst and your role is to analyze the underline data pattern. 

        Goals:
        - Summarize product-level performance.
        - Calculate total revenue, cost, and profit margins.
        - Flag low-profit or loss-making products.
        - Recommend discontinuation candidates.

        Focus:
        - Order quantities, purchase and selling prices.
        - Profitability trends by region.
        - Actionable insights.

        Currency:
        - Format totals using country-specific symbols.
        - Multiply unit prices by quantities.
        - Note missing/ambiguous currency data.

        Formatting:
        - Use headings and bullet points.
        - Highlight key metrics and recommendations.
        - Keep tone professional and concise.
        """
    )

    # 📈 Visualization expert agent that outputs Plotly charts
    visualizer_analyst = AssistantAgent(
        name="visualizer_analyst",
        model_client=model_client,
        system_message="""
        You are a data visualization expert. Use Matplotlib to create clear, professional visuals from sales analysis outputs provided by `get_sales_data`.
        Please provide `CodeExecutor` in a one markdown-encoded code block to execute (i.e., quoting code in ```python or ```sh code blocks)

        Goals:
        - Generate charts to illustrate product performance, revenue, cost, and profit margins.
        - Highlight trends across countries and regions.
        - Visualize low-performing products and profitability patterns.

        Instructions:
        - Use Plotly only.
        - Choose appropriate chart types (e.g., bar, line, pie, heatmap).
        - Label axes, legends, and currency units clearly.
        - Save each visual as a file in the working directory and print its location.
        - Display the image

        Formatting:
        - Keep visuals clean and easy to interpret.
        - Group related metrics for comparison.
        - Ensure visuals support actionable insights.
        """
    )

    # 🛠️ Code executor agent to run Python code
    CodeExecutor = CodeExecutorAgent(
        name="CodeExecutor",
        code_executor=LocalCommandLineCodeExecutor(work_dir="CodeExecutionEnv"),
        system_message="""
        Execute Python code from 'visualizer_analyst' in the working directory. 
        There is `No` experted *OUTPUT**. 
        Notify 'DbCodeCreator' saying 'This is Done' to confirm that all scripts 
        When saving a chart, print the fully qualified path of the saved file. On a new line, output: GENERATED:<full_path_to_file>.
        then End with: "done"
        """
    )

    # 🧠 Group chat engine for multi-agent handoff
    group_chat = RoundRobinGroupChat(
        participants=[user_proxy, get_sales_data, sales_analyst, visualizer_analyst, CodeExecutor],
        termination_condition=TextMentionTermination("done"),
        max_turns=10
    )

    # 🔁 Run a sample task through the pipeline
    cancellation_token = CancellationToken()
    stream = group_chat.run_stream(task="Can you give me a summary of bicycle sales by country?", cancellation_token=cancellation_token)

    async for item in stream:
        if isinstance(item, BaseMessage):
            print(f"\n ### 🧠  {item.source.upper()} 🧠 ###")
            print(item.content)


# -------------------------------
# 🏁 Entry Point
# -------------------------------

async def main():
    """
    Main entry point for launching the AI team.
    """
    await initialize_ai_agent_team()

# ⏯️ Run async main if executed directly
if __name__ == "__main__":
    asyncio.run(main())
```
