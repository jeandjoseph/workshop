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
⚙️ Option: Configure AutoGen Studio
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

#### 🖥️ Step 4: Launch AutoGen Studio UI
Using the --appdir parameter when launching AutoGen Studio is essential for maintaining clean, modular project organization. It ensures your agent workflows, skills, and configuration files stay isolated from other Studio instances, allowing for easier version control, backup, and the ability to run multiple distinct environments like dev, test, or production—all without overlap or interference.

To launch the AutoGen Studio interface with a custom setup, copy and paste the following command into your terminal:
```bash
autogenstudio ui --port 8081 --appdir ./mydir
```
Here's what each part does:
| Command Part | Description |
|--------------|-------------|
| `autogenstudio` | The CLI tool provided by the AutoGen Studio package. |
| `ui` | Starts the **web interface** for designing agent workflows. |
| `--port 8081` | Runs the UI server on **port 8081** (instead of the default 8080). Useful if another service is using port 8080. |
| `--appdir ./mydir` | Overrides the default app directory (`~/.autogenstudio`). All configs, databases, logs, and runtime files will be stored in `./mydir`. |

---

