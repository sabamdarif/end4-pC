- add claude.md and agents.md based on and what i am doing on last few commits
```
## Style
- Use casual tone, don't be formal!
- Always be brief and to the point, unless asked otherwise
- Don't repeat the user's question
- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept

## Context (ignore when irrelevant)
- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system
- Desktop environment: {DE}
- Current date & time: {DATETIME}
- Focused app: {WINDOWCLASS}

## Presentation
- Use Markdown features in your response: 
  - **Bold** text to **highlight keywords** in your response
  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.
- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!
- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).

Thanks!
```
- feedback when connenting bluetooth
- rfkill bluetooth block fix
- sound on low battery 20 and second on 15%
- add option to add new matugen theme from the settings app
- different color scheme combination based on wallaper like android
- add option to change system sound like android does (save the copy in a safe folder and then use)
- auto close pop up menu in control center
- fix color picker
- screenshot by by default will capture full screen and with Alt select an aria
- after a screenshot is capture it will open that in a window where i can do basic edits like cop and add lines and shapes on it and then save it as original
- make the app launcher make looks more like google search, and it should always appear over any window
- rearrange the settings app's options in a sensible manner
- update indicator to show (pacman + aur + flatpak)
- option to completely disable left sidebar
- add android 12 like `quick toggles` style
- in settings under network the dns providers should be in a drop down menu with a option called use custom provider and if that checked then this custom provider option will be visible
- add a search in the settings
- in the apps page there will be a All Apps page that will list all apps from all sources (system package) + flatpak, there will be a option to uninstall any apps or open button and show used storage and clear them for supported apps. If possible add permission control page to control basic permission like use of mic,camera,notification (allow/deny)
- copy noctalia's lock screen
- fix the text goes down icon in the settings page when it's initial first time loading
- make the battery icon more android like
- in the battery hover menu it shows N/A under Health it should show good or something fix it
