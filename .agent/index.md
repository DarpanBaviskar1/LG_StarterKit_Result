# ⚠️ NOTICE: Structure Updated (2026-02-10)

## 🆕 This folder has been reorganized!

**The old structure with `foundations/`, `domains/`, `roles/`, and `workflows/` has been replaced with a new numbered hierarchy for improved navigation.**

---

## 🚀 Start Here: [README.md](README.md)

**The main entry point is now:** [`README.md`](README.md)

This file contains:
- 🎯 Decision tree navigation (find info by situation)
- 📂 New folder structure (1-8 numbered folders)
- 🎓 Usage scenarios with examples
- 📖 Recommended reading order
- ⚡ Quick search guide

---

## 🗂️ New Folder Structure

```
.agent/
├── README.md              ← START HERE (Main entry point)
├── QUICK_REFERENCE.md     ← 1-page cheat sheet for common tasks
│
├── 1-foundations/         ← Core principles (GOLDEN_RULES, ARCHITECTURE)
├── 2-patterns/            ← How-to patterns (SSH, KML, service layer)
├── 3-features/            ← Completed feature docs (KML Agent, APIs)
├── 4-guides/              ← Step-by-step tutorials
├── 5-templates/           ← Copy-paste code (Flutter, KML)
├── 6-roles/               ← AI agent specializations
├── 7-workflows/           ← Multi-step processes (feature dev, debugging)
└── 8-troubleshooting/     ← Problem→Solution mapping
```

---

## 📖 Migration Guide

### Old Location → New Location

| Old Path | New Path |
|----------|----------|
| `foundations/GOLDEN_RULES.md` | [`1-foundations/GOLDEN_RULES.md`](1-foundations/GOLDEN_RULES.md) |
| `foundations/REFACTOR_SUMMARY.md` | [`1-foundations/REFACTOR_HISTORY.md`](1-foundations/REFACTOR_HISTORY.md) |
| `domains/flutter/.../01-core-patterns/ssh-communication.md` | [`2-patterns/ssh-patterns.md`](2-patterns/ssh-patterns.md) |
| `domains/flutter/.../01-core-patterns/kml-management.md` | [`2-patterns/kml-patterns.md`](2-patterns/kml-patterns.md) |
| `domains/flutter/.../01-core-patterns/state-management.md` | [`2-patterns/state-management.md`](2-patterns/state-management.md) |
| `domains/flutter/.../best-practices.md` | [`4-guides/flutter/best-practices.md`](4-guides/flutter/best-practices.md) |
| `domains/flutter/.../common-mistakes.md` | [`4-guides/flutter/common-mistakes.md`](4-guides/flutter/common-mistakes.md) |
| `domains/flutter/.../03-code-templates/*.dart` | [`5-templates/flutter/*.dart`](5-templates/flutter/) |
| `roles/lg-init/SKILL.md` | [`6-roles/lg-init.md`](6-roles/lg-init.md) |
| `roles/lg-exec/SKILL.md` | [`6-roles/lg-exec.md`](6-roles/lg-exec.md) |
| `workflows/test-rig.md` | [`7-workflows/testing.md`](7-workflows/testing.md) |
| `kml_agent/skill.md` | [`3-features/kml-agent.md`](3-features/kml-agent.md) |

---

## 🎯 Quick Access by Task

| What You Need | Go To |
|---------------|-------|
| **Instant lookup** | [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md) |
| **Understand system** | [`1-foundations/ARCHITECTURE.md`](1-foundations/ARCHITECTURE.md) |
| **Learn patterns** | [`2-patterns/`](2-patterns/) |
| **See examples** | [`3-features/`](3-features/) |
| **Get code templates** | [`5-templates/`](5-templates/) |
| **Debug issues** | [`8-troubleshooting/`](8-troubleshooting/) |
| **Build feature** | [`7-workflows/feature-development.md`](7-workflows/feature-development.md) |
| **Choose AI role** | [`6-roles/README.md`](6-roles/README.md) |

---

## ✨ Key Improvements

**Why the change?**
- ✅ **Numbered folders** create clear hierarchy and reading order
- ✅ **Decision tree navigation** helps find info by situation (not just by topic)
- ✅ **Quick reference** provides instant lookup for common tasks
- ✅ **Flatter structure** reduces excessive nesting (was 7 levels deep!)
- ✅ **Task-oriented** organization (workflow-first, not just reference material)
- ✅ **Comprehensive troubleshooting** with problem→solution mapping

**Result:** Find information in <30 seconds instead of searching through nested directories!

---

## 🚨 Critical Rules (Unchanged)

These core principles remain the same:

- **SSH Operations:** Always use `client!.run(command)` → [1-foundations/GOLDEN_RULES.md](1-foundations/GOLDEN_RULES.md)
- **KML Files:** Only send to `master.kml` → [1-foundations/GOLDEN_RULES.md](1-foundations/GOLDEN_RULES.md)
- **State Management:** Use Riverpod 3.x → [2-patterns/state-management.md](2-patterns/state-management.md)
- **Service Layer:** HTTP vs SSH separation → [2-patterns/service-layer.md](2-patterns/service-layer.md)

---

## 📊 New Content Added

In addition to reorganizing, we've added:

**New Documentation (6,000+ lines):**
- 📖 [`README.md`](README.md) - Main entry point with decision trees (250 lines)
- ⚡ [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md) - 1-page cheat sheet (300 lines)
- 🏗️ [`1-foundations/ARCHITECTURE.md`](1-foundations/ARCHITECTURE.md) - System design (500 lines)
- 🔧 [`2-patterns/service-layer.md`](2-patterns/service-layer.md) - Service patterns (800 lines)
- 🎭 [`6-roles/README.md`](6-roles/README.md) - Role selection guide (600 lines)
- 🚀 [`7-workflows/feature-development.md`](7-workflows/feature-development.md) - End-to-end workflow (700 lines)
- 🔍 [`7-workflows/debugging.md`](7-workflows/debugging.md) - Systematic debugging (600 lines)
- ⚠️ [`8-troubleshooting/api-errors.md`](8-troubleshooting/api-errors.md) - API debugging (1,000 lines)

**New Feature Documentation (2,500+ lines):**
- 📍 [`3-features/location-lookup.md`](3-features/location-lookup.md) - Nominatim integration
- ☁️ [`3-features/weather-overlay.md`](3-features/weather-overlay.md) - Open-Meteo integration
- 🌍 [`3-features/earthquake-tracker.md`](3-features/earthquake-tracker.md) - USGS integration

**New Templates:**
- 📁 [`5-templates/kml/`](5-templates/kml/) - KML templates with usage guide

---

## 💡 Next Steps

1. **Bookmark** [`README.md`](README.md) as your starting point
2. **Read** [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md) for instant lookups
3. **Explore** numbered folders in order (1 → 8)
4. **Use decision tree** in README when searching for specific info

---

**Last Updated:** February 10, 2026  
**Migration Date:** February 10, 2026  
**Old Structure:** Archived (can be removed after verification)  
**New Structure:** Numbered hierarchy (1-8) with task-based navigation
