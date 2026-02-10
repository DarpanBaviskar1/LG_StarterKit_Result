# 🤖 .agent Folder - AI Agent Knowledge Base

**Purpose:** Structured knowledge for AI agents working on the LG Controller project.

---

## 🚀 Quick Start for Agents

### First Time Working on This Project?
1. Read [1-foundations/GOLDEN_RULES.md](1-foundations/GOLDEN_RULES.md) ← **CRITICAL**
2. Skim [QUICK_REFERENCE.md](QUICK_REFERENCE.md) ← **ONE-PAGE CHEAT SHEET**
3. Check [6-roles/README.md](6-roles/README.md) to understand your specialization

### Working on a Specific Task?
Use this decision tree:

```
┌─ Need to understand WHY things are done a certain way?
│  → Read 1-foundations/
│
┌─ Need to know HOW to implement something?
│  → Check 2-patterns/ or 4-guides/
│
┌─ Need ready-made code?
│  → Use 5-templates/
│
┌─ Studying an existing feature?
│  → Browse 3-features/
│
┌─ Stuck with an error?
│  → Search 8-troubleshooting/
│
└─ Need to follow a process?
   → Check 7-workflows/
```

---

## 📂 Folder Structure

```
.agent/
├── README.md                    ← You are here
├── QUICK_REFERENCE.md           ← 1-page cheat sheet for common tasks
│
├── 1-foundations/               ← Core principles (READ FIRST)
│   ├── GOLDEN_RULES.md          ← Non-negotiable patterns
│   ├── REFACTOR_HISTORY.md      ← Learn from past mistakes
│   └── ARCHITECTURE.md          ← System design decisions
│
├── 2-patterns/                  ← How to do things correctly
│   ├── ssh-patterns.md          ← SSH communication patterns
│   ├── kml-patterns.md          ← KML generation patterns
│   ├── state-management.md      ← Riverpod patterns
│   └── service-layer.md         ← Service architecture
│
├── 3-features/                  ← Completed feature documentation
│   ├── kml-agent/               ← AI-powered KML generation
│   ├── location-lookup/         ← Geocoding integration
│   ├── weather-overlay/         ← Weather data visualization
│   └── earthquake-tracker/      ← Seismic data display
│
├── 4-guides/                    ← Step-by-step tutorials
│   ├── flutter/                 ← Flutter-specific guides
│   └── web/                     ← Web development guides
│
├── 5-templates/                 ← Copy-paste ready code
│   ├── flutter/                 ← Flutter code templates
│   └── kml/                     ← KML file templates
│
├── 6-roles/                     ← AI agent specializations
│   ├── README.md                ← When to use which role
│   ├── lg-init.md               ← Project initialization
│   ├── lg-brainstormer.md       ← Feature ideation
│   ├── lg-plan-writer.md        ← Detailed planning
│   ├── lg-exec.md               ← Implementation
│   └── lg-code-reviewer.md      ← Code quality audit
│
├── 7-workflows/                 ← Multi-step processes
│   ├── feature-development.md   ← End-to-end feature creation
│   ├── testing.md               ← Testing procedures
│   └── debugging.md             ← Systematic debugging
│
└── 8-troubleshooting/           ← Problem → Solution mapping
    ├── ssh-issues.md            ← SSH connection problems
    ├── kml-errors.md            ← KML validation issues
    ├── state-bugs.md            ← State management problems
    └── api-errors.md            ← API integration issues
```

---

## 🎯 Usage Scenarios

### Scenario 1: "Create a new feature"
```
1. Activate role: 6-roles/lg-brainstormer.md
2. Read: 1-foundations/GOLDEN_RULES.md
3. Check patterns: 2-patterns/service-layer.md
4. Use template: 5-templates/flutter/service-template.dart
5. Follow workflow: 7-workflows/feature-development.md
6. Reference similar: 3-features/earthquake-tracker/
```

### Scenario 2: "Fix SSH connection error"
```
1. Check: 8-troubleshooting/ssh-issues.md
2. Verify patterns: 2-patterns/ssh-patterns.md
3. Compare with: 1-foundations/GOLDEN_RULES.md
```

### Scenario 3: "Review code quality"
```
1. Activate role: 6-roles/lg-code-reviewer.md
2. Check against: 1-foundations/GOLDEN_RULES.md
3. Verify patterns: 2-patterns/ (all files)
4. Reference: 4-guides/flutter/common-mistakes.md
```

### Scenario 4: "Learn the project"
```
1. Start: 6-roles/lg-init.md
2. Read: 1-foundations/ARCHITECTURE.md
3. Study: 3-features/ (all completed features)
4. Practice: 5-templates/ (copy and modify)
```

---

## 📖 Reading Order for New Agents

**Day 1 - Foundations (30 min)**
1. This README
2. QUICK_REFERENCE.md
3. 1-foundations/GOLDEN_RULES.md
4. 1-foundations/ARCHITECTURE.md

**Day 2 - Patterns (1 hour)**
1. 2-patterns/ssh-patterns.md
2. 2-patterns/kml-patterns.md
3. 2-patterns/state-management.md
4. 4-guides/flutter/common-mistakes.md

**Day 3 - Application (2 hours)**
1. Browse 3-features/ (understand completed work)
2. Study 5-templates/ (ready-made code)
3. Try implementing something from 7-workflows/

---

## 🔍 Quick Search Guide

### "How do I...?"
- **Connect to LG via SSH?** → 2-patterns/ssh-patterns.md
- **Generate KML?** → 2-patterns/kml-patterns.md
- **Create a new screen?** → 5-templates/flutter/screen-template.dart
- **Add a service?** → 2-patterns/service-layer.md
- **Manage state?** → 2-patterns/state-management.md

### "What if...?"
- **SSH connection fails?** → 8-troubleshooting/ssh-issues.md
- **KML doesn't validate?** → 8-troubleshooting/kml-errors.md
- **State doesn't update?** → 8-troubleshooting/state-bugs.md
- **API returns error?** → 8-troubleshooting/api-errors.md

### "Show me examples of...?"
- **Completed features** → 3-features/
- **Flutter code** → 5-templates/flutter/
- **KML files** → 5-templates/kml/

---

## 🎓 For Human Developers

This folder helps AI agents:
- ✅ Remember project conventions across sessions
- ✅ Apply consistent patterns automatically
- ✅ Avoid repeating past mistakes
- ✅ Generate code matching your architecture
- ✅ Provide educational explanations

**How to use it:**
- Point agents to specific files when asking questions
- Update documentation when patterns change
- Add new features to `3-features/` after completion
- Keep `QUICK_REFERENCE.md` updated with common tasks

---

## 📊 Folder Metrics

- **Read time:** 3-4 hours (full documentation)
- **Quick reference:** 5 minutes (QUICK_REFERENCE.md)
- **Common task lookup:** <30 seconds
- **Code templates:** Copy-paste ready
- **Troubleshooting coverage:** 90%+ of common issues

---

## 🔄 Version History

- **v2.0** (2026-02-10): Complete restructuring for clarity
- **v1.0** (2026-01): Initial documentation structure

---

**Remember:** The `.agent` folder exists to make AI agents more effective. If something is hard to find or unclear, update the documentation!
