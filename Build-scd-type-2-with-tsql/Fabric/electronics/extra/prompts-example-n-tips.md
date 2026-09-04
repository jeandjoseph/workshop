### Quick descriptive analytics

  - Revenue snapshot: "Give me total revenue, order count, active customers, and AOV for the most recent complete month. Show a KPI card layout and flag any metric that dropped versus the prior month."
  - Category mix: "Show revenue and units sold by product category for the last 90 days. Recommend a horizontal bar chart sorted by revenue, and highlight the top and bottom category."
  - Regional performance: "Break down revenue by region with share of total, then recommend a bar chart with region on the x-axis, revenue on the y-axis, and share percentage as a data label."

### Trend and time-series analysis

  - Monthly trend with MoM growth: "Plot monthly revenue across all available history and show month-over-month growth percentage. Recommend a combo chart with revenue as bars and MoM percent as a line on a secondary axis. Call out the best and worst month."
  - Quarterly category trend: "Show quarterly revenue per product category. Recommend a multi-series line chart and tell me which category is accelerating versus decelerating."
  - Day-of-week seasonality: "Aggregate orders and revenue by day of the week. Recommend a bar chart and tell me which days are strongest."

### Ranking and top-N analysis

  - Top products by revenue: "Top 10 products by revenue in the last 90 days, with category and units sold. Recommend a horizontal bar chart sorted descending and color-code bars by category."
  - Top customers by lifetime spend: "Top 5 customers by lifetime spend with their region, total orders, and favorite category. Recommend a table visual and suggest one outreach idea per customer."
  - Bottom performers: "Show the bottom 10 products by revenue that still have at least one sale. Recommend a bar chart and flag any product whose average review rating is also below 3."

### Voice of customer and sentiment

  - Sentiment mix per category: "Show the count of Positive, Negative, Neutral, and Mixed reviews per product category, plus the average rating. Recommend a 100% stacked bar chart with category on the y-axis and sentiment as series."
  - Most-loved products: "List the top 10 products by average rating with at least 3 reviews. Recommend a horizontal bar chart and include the dominant sentiment as a label."
  - Theme detection: "Summarize the most common complaints from negative reviews across all Electronics products. Group them into 3 to 5 themes with example quotes and recommend a word-cloud or theme-frequency bar chart."

### Diagnostic and cross-analysis (sales + reviews)

  - Risk products (high revenue, low rating): "Find products with revenue in the top quartile but average rating below 3. Recommend a scatter plot with revenue on the x-axis and average rating on the y-axis, with bubble size as review count. These are retention risks."
  - Hero products (high revenue + high rating): "List products that are both in the top 10 by revenue and have average rating of 4 or higher. Recommend a quadrant scatter chart and label these as 'hero products'."
  - Region versus sentiment: "Compare average review rating and revenue per region. Recommend a grouped bar chart and tell me if any region has a satisfaction gap relative to its revenue contribution."

### Customer 360 and cohort analysis

  - Cohort by signup quarter: "Group customers by their signup quarter and show average lifetime spend and order frequency per cohort. Recommend a heatmap with signup quarter on one axis and metric on the other."
  - New versus returning revenue: "Split revenue between first-time buyers and repeat buyers for the last 6 months. Recommend a stacked area chart over time."
  - Customer-product affinity: "For the top 5 customers by spend, show their top 3 categories purchased. Recommend a treemap grouped by customer."

### Executive board pack (multi-question prompt)

  - One-shot board summary: "Build me a 1-page executive summary for the last 90 days covering: (1) revenue, orders, AOV with MoM change, (2) top 5 categories by revenue, (3) regional split, (4) average review rating with sentiment mix, (5) top 3 risk products (high revenue, low rating). Recommend one visual per section and end with 3 bolded takeaways and 2 action items."

### (Tips)How to get the best results

  - Be explicit about the time window ("last 30 days", "Q1 2025") so the agent does not fall back to the default.
  - Always ask for the visual recommendation at the end of the prompt. The agent is trained to pick chart type + axes + takeaway only when asked.
  - Stack 2 to 3 related questions in one prompt when building dashboards. The agent will return a coordinated set of SQL + visuals instead of one-offs.
  - Use comparative language ("versus prior month", "share of total", "top quartile") to unlock window-function patterns from the system prompt.