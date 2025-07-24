## ⚙️ Installing Microsoft AutoGen Studio 0.4+
[AutoGen Studio](https://microsoft.github.io/autogen/stable/user-guide/autogenstudio-user-guide/index.html) is a low-code web interface built on top of Microsoft’s AutoGen framework. It lets you visually design, configure, and run multi-agent AI workflows perfect for prototyping agentic systems without diving deep into backend code.

🧠 What AutoGen Studio Offers
- **Agent Creation**: Drag-and-drop agent workflow creation with roles, models, and skills.
- **Workflow Design**: Set up how agents interact (e.g., group chat, sequential).
- **Skill Management**: Add Python-based skills like image generation or data scraping.
- **Model Integration**: Use Azure OpenAI, OpenAI, Gemini, or even local LLMs via LM Studio or Ollama.
- **Playground UI**: Test workflows in real time and watch agents collaborate.

#### 📦 Step 1: Installing Microsoft AutoGen Studio 0.4+
- 🧠 Ensure your [virtual environment](../pages/CreatePythonVirtualEnv.md) is **active** before proceeding.
- Paste the following commands into your terminal to install core libraries and extensions:
```bash
pip install -U autogenstudio
```
⏳ Sit back while the packages install, you’re laying the foundation for agent workflows, environment config, and UI demos!

#### 🔐 Step 2: Validate If AutoGen Studio is successfully installed
```bash
pip show autogenstudio
```
You should see a screen similar to the one shown below.
![](/AgentcisAI/ms-autogen/intro-to-ms-autogen/docs/images/verifyautogenstudioinstalled.png)

#### 🔐 Step 3: Setting Up Azure OpenAI Key for AutoGen Studio
To use Azure OpenAI with [Microsoft AutoGen Studio](https://microsoft.github.io/autogen/stable/index.html), you need to configure your API credentials so agents can access models securely.

✅ Gather Your Azure OpenAI Credentials
From the [Azure Portal](https://portal.azure.com), locate your Azure OpenAI resource and copy:
- `AZURE_OPENAI_API_KEY` (either Key 1 or Key 2)
- `AZURE_OPENAI_ENDPOINT` (e.g., `https://your-resource-name.openai.azure.com`)
- `DEPLOYMENT_NAME` (your model deployment name, e.g., `gpt-4`)
- `API_VERSION` (e.g., `2024-02-01`)

🧪 Set Environment Variables
In your terminal or `.env` file:
```bash
export AZURE_OPENAI_API_KEY="your-api-key"
export AZURE_OPENAI_ENDPOINT="https://your-resource-name.openai.azure.com"
```
⚙️ Configure AutoGen Studio
When defining your agent or workflow, use the following llm_config:
```bash
llm_config = {
  "config_list": [
    {
      "model": "your-deployment-name",
      "api_key": os.environ["AZURE_OPENAI_API_KEY"],
      "base_url": os.environ["AZURE_OPENAI_ENDPOINT"],
      "api_type": "azure",
      "api_version": "2024-02-01"
    }
  ]
}
```
You can also enter this configuration directly in AutoGen Studio’s JSON editor if you're using the UI.

💡 Tip: For production use, consider Azure Identity and RBAC authentication instead of raw API keys for enhanced security.
