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
