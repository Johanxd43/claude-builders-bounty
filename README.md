{
  "nodes": [
    {
      "parameters": {
        "cron": {
          "expression": "0 17 * * 5"
        }
      },
      "name": "Weekly Trigger",
      "type": "cron",
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "GET",
        "url": "https://api.github.com/repos/{{ $json[\"repo_owner\"] }}/{{ $json[\"repo_name\"] }}/commits?since={{ $date.subtract('P7D').toISOString() }}&until={{ $date.toISOString() }}",
        "headerParameters": {
          "Authorization": "Bearer {{ $env.GITHUB_TOKEN }}"
        }
      },
      "name": "Fetch Commits",
      "type": "httpRequest",
      "position": [500, 300]
    },
    {
      "parameters": {
        "method": "GET",
        "url": "https://api.github.com/repos/{{ $json[\"repo_owner\"] }}/{{ $json[\"repo_name\"] }}/issues?state=closed&since={{ $date.subtract('P7D').toISOString() }}",
        "headerParameters": {
          "Authorization": "Bearer {{ $env.GITHUB_TOKEN }}"
        }
      },
      "name": "Fetch Closed Issues",
      "type": "httpRequest",
      "position": [500, 400]
    },
    {
      "parameters": {
        "method": "GET",
        "url": "https://api.github.com/repos/{{ $json[\"repo_owner\"] }}/{{ $json[\"repo_name\"] }}/pulls?state=merged&since={{ $date.subtract('P7D').toISOString() }}",
        "headerParameters": {
          "Authorization": "Bearer {{ $env.GITHUB_TOKEN }}"
        }
      },
      "name": "Fetch Merged PRs",
      "type": "httpRequest",
      "position": [500, 500]
    },
    {
      "parameters": {
        "functionCode": "// Aggregate GitHub activity data for Claude narrative generation\nconst commits = $json[0] || [];\nconst issues = $json[1] || [];\nconst prs = $json[2] || [];\nconst repoOwner = $json[3] || 'unknown';\nconst repoName = $json[4] || 'repository';\nlet summary = `Weekly activity for ${repoOwner}/${repoName}\\n`;\nsummary += `**Commits:** ${commits.length}\\n`;\nsummary += `**Closed Issues:** ${issues.length}\\n`;\nsummary += `**Merged PRs:** ${prs.length}\\n`;\nreturn [{ json: { aggregate: summary, repoOwner, repoName } }];"
      },
      "name": "Aggregate Data",
      "type": "function",
      "position": [750, 400]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "jsonParameters": true,
        "bodyParameters": {
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 1000,
          "temperature": 0.5,
          "system": "You are a technical writer. Generate a concise, engaging weekly narrative summary of the provided GitHub repository activity. Use the aggregated data. Language: {{ $json[\"language\"] || 'EN' }}. Make it suitable for Discord delivery.",
          "messages": [{ "role": "user", "content": "{{ $json[\"aggregate\"] }}"]}]
        },
        "headerParameters": {
          "x-api-key": "{{ $env.ANTHROPIC_API_KEY }}",
          "content-type": "application/json"
        }
      },
      "name": "Claude Summary",
      "type": "httpRequest",
      "position": [1000, 400]
    },
    {
      "parameters": {
        "mode": "response",
        "value": "{{ $json[\"text\"] }}",
        "property": "value"
      },
      "name": "Extract Summary",
      "type": "set",
      "position": [1250, 400]
    },
    {
      "parameters": {
        "enableButtons": false,
        "enableFollowUp": false,
        "webhookUrl": "{{ $env.DISCORD_WEBHOOK_URL }}",
        "message": "{{ $json[\"summary\"] }}",
        "channelName": "weekly-repo-summary"
      },
      "name": "Discord Webhook",
      "type": "discord",
      "position": [1500, 400]
    }
  ],
  "connections": {
    "main": [
      [{"node": "Fetch Commits", "type": "main", "index": 0}, {"node": "Aggregate Data", "type": "main", "index": 0}],
      [{"node": "Fetch Closed Issues", "type": "main", "index": 0}, {"node": "Aggregate Data", "type": "main", "index": 1}],
      [{"node": "Fetch Merged PRs", "type": "main", "index": 0}, {"node": "Aggregate Data", "type": "main", "index": 2}],
      [{"node": "Aggregate Data", "type": "main", "index": 0}, {"node": "Claude Summary", "type": "main", "index": 0}],
      [{"node": "Claude Summary", "type": "main", "index": 0}, {"node": "Extract Summary", "type": "main", "index": 0}],
      [{"node": "Extract Summary", "type": "main", "index": 0}, {"node": "Discord Webhook", "type": "main", "index": 0}]
    ]
  },
  "active": false,
  "settings": {},
  "id": "n8n-weekly-repo-summary",
  "meta": {}
}