# Lana V2 — Branching Strategy

Lana V2 is a ground-up rebuild of the Lana iOS application. The project is primarily focused on learning and understanding the technical side of iOS development, including architecture, data flow, frameworks, state management, testing, and software development practices.

Since Lana V2 has one main product capability with several relatively independent sub-features, the repository uses a simple branching strategy to keep development organized without introducing unnecessary complexity.

---

## Branching Strategy

This repository uses three primary branch types:

| Branch                  | Purpose                                              |
| ----------------------- | ---------------------------------------------------- |
| `main`                  | Stable version of the application                    |
| `development`           | Active integration and testing branch                |
| `feature/<branch-name>` | Development of a specific application feature        |
| `Tech/<branch-name>`    | Optional technical experiments and proof of concepts |

The `Tech/` branch is optional and should only be used when a technical question needs to be investigated before implementing it as part of the application.

---

## Branch Structure

The main development flow is:

```text
feature/<branch-name>
        │
        ▼
   development
        │
        ▼
      main
```

For technical exploration:

```text
Tech/<branch-name>
        │
        ▼
Technical Learning / POC
        │
        ▼
feature/<branch-name>
        │
        ▼
development
        │
        ▼
main
```

---

# Branches

## `main`

`main` contains the most stable version of Lana V2.

It should:

* Build successfully
* Contain tested and stable changes
* Represent a working version of the application
* Not be used for experiments or day-to-day development

Changes should be merged into `main` only after they have been integrated and tested in `development`.

---

## `development`

`development` is the main integration branch.

It represents the latest version of Lana V2 that is actively being developed and tested.

Use it to:

* Integrate completed features
* Test interactions between features
* Perform regression testing
* Identify integration problems
* Prepare changes for `main`

Feature development should not happen directly on `development`.

Instead:

```text
feature/*
    ↓
development
```

---

## `feature/<branch-name>`

Feature branches are used to develop meaningful pieces of Lana V2.

Examples:

```text
feature/route-creation
feature/route-generation
feature/route-options
feature/route-details
feature/saved-routes
feature/live-navigation
feature/ride-summary
feature/apple-watch
```

A feature branch can contain multiple related screens, components, models, services, and tests.

For example:

```text
feature/route-creation
```

may include:

* Route type selection
* Target distance input
* Start point selection
* Destination selection
* Input validation
* Related UI states

There is no need to create a separate branch for every screen or component.

### Branching Principle

Create a new feature branch when the work represents a meaningful, independently understandable piece of functionality.

Avoid creating branches for very small changes such as:

```text
feature/change-button-color
feature/fix-spacing
feature/change-title
```

unless the change is large enough to require independent development.

Small changes can usually be included in the relevant feature branch.

---

# `Tech/<branch-name>`

Technical branches are optional.

Use them when you need to explore or understand a technical problem before implementing it in the actual application.

Examples:

```text
Tech/mapkit-route-generation
Tech/core-location-tracking
Tech/swiftdata-persistence
Tech/voice-navigation
Tech/watch-connectivity
```

A `Tech/` branch may be used to answer questions such as:

> How does `MKDirections` generate a route?

> How can I calculate whether the generated route is close enough to the target distance?

> How should CoreLocation provide continuous location updates?

> How can SwiftData persist a route?

> How can WatchConnectivity synchronize navigation data?

The goal of a `Tech/` branch is **learning and validation**, not necessarily producing production-ready code.

---

## Technical Exploration Workflow

A technical investigation can follow this process:

```text
Technical Question
        ↓
Tech/<branch-name>
        ↓
Experiment / Proof of Concept
        ↓
Understand the Framework / API
        ↓
Test the Approach
        ↓
Document Findings
        ↓
Make Technical Decision
        ↓
Implement Properly
        ↓
feature/<branch-name>
```

For example:

```text
Question:
How can Lana generate a route close to a target distance?

        ↓

Tech/mapkit-route-generation

        ↓

Explore:
- MKDirections
- MKRoute
- Route distance
- Route alternatives
- Route calculation limitations

        ↓

Document findings

        ↓

Decide on implementation approach

        ↓

feature/route-generation
```

This allows technical experiments to remain isolated from the main application code.

---

# Recommended Merge Flow

For normal feature development:

```text
feature/route-generation
          │
          ▼
    Pull Request
          │
          ▼
    development
          │
          ▼
 Integration Testing
          │
          ▼
    Pull Request
          │
          ▼
        main
```

### Process

1. Create a feature branch from `development`.
2. Develop and test the feature.
3. Commit changes using Conventional Commits.
4. Push the branch to GitHub.
5. Create a Pull Request to `development`.
6. Review and test the changes.
7. Merge into `development`.
8. Delete the feature branch when it is no longer needed.
9. When `development` is stable, merge it into `main`.

---

# Branch Naming

Use names that are:

* Short
* Descriptive
* Specific
* Written in lowercase for feature names
* Separated using `-`

### Examples

```text
feature/route-generation
feature/live-navigation
feature/saved-routes

Tech/mapkit-route-generation
Tech/core-location
Tech/swiftdata
Tech/watch-connectivity
```

The branch name should describe **what you are working on**, not how you feel about the work.

Avoid:

```text
feature/new
feature/test
feature/final
feature/fix
feature/my-work
```

Prefer:

```text
feature/route-generation
feature/navigation-rerouting
feature/ride-summary
```

---

# Repository Rules

## 1. Do Not Develop Directly on `main`

Do not use `main` as your development workspace.

Create a feature branch instead:

```bash
git switch development
git pull origin development
git switch -c feature/<branch-name>
```

---

## 2. Do Not Force Push to `main`

Never force push to `main`.

Do not run:

```bash
git push --force origin main
```

or:

```bash
git push -f origin main
```

Changes should go through the appropriate Pull Request and merge process.

---

## 3. Keep Branches Focused

A branch should have one clear purpose.

Good:

```text
feature/live-navigation
```

Avoid combining unrelated work:

```text
feature/navigation-weather-watch-database
```

If several pieces of work are independent, consider creating separate feature branches.

---

## 4. Delete Completed Branches

Once a feature or technical experiment has been completed and merged, delete the branch if it is no longer needed.

Delete a local branch:

```bash
git branch -d <branch-name>
```

Delete a remote branch:

```bash
git push origin --delete <branch-name>
```

Example:

```bash
git branch -d feature/route-generation
git push origin --delete feature/route-generation
```

---

# Conventional Commits

Lana V2 uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Format:

```text
<type>[optional scope]: <description>
```

### Examples

```text
feat(route): add target distance input
feat(navigation): add turn instruction handling
fix(location): handle unavailable GPS updates
refactor(route): separate route generation logic
test(route): add route distance validation
docs(architecture): document MVVM responsibilities
chore(project): configure SwiftData container
```

### Common Commit Types

| Type       | Purpose                                     |
| ---------- | ------------------------------------------- |
| `feat`     | Add a new feature                           |
| `fix`      | Fix a bug                                   |
| `refactor` | Restructure code without changing behavior  |
| `test`     | Add or modify tests                         |
| `docs`     | Update documentation                        |
| `chore`    | Maintenance work                            |
| `perf`     | Performance improvements                    |
| `build`    | Build system or dependency changes          |
| `ci`       | CI/CD changes                               |
| `style`    | Formatting changes that do not affect logic |

Avoid vague commit messages:

```text
update
fix
done
final
try again
new
revision
```

Prefer descriptive messages:

```bash
git commit -m "feat(route): add target distance validation"
```

```bash
git commit -m "fix(navigation): prevent duplicate turn announcements"
```

```bash
git commit -m "docs(architecture): document repository pattern"
```

---

# Getting Started

## Clone the Repository

Clone the repository:

```bash
git clone <repository-url>
```

Navigate into the project:

```bash
cd Lana-V2
```

Check the remote:

```bash
git remote -v
```

---

# Start New Development

Before starting new work, make sure your local `development` branch is up to date:

```bash
git switch development
git pull origin development
```

Create a new feature branch:

```bash
git switch -c feature/<branch-name>
```

Example:

```bash
git switch -c feature/route-generation
```

---

# Add Changes

Check the current state:

```bash
git status
```

Add a specific file:

```bash
git add <file-name>
```

Or add all changes:

```bash
git add .
```

Review staged changes:

```bash
git status
```

---

# Commit Changes

Use Conventional Commits:

```bash
git commit -m "type(scope): description"
```

Example:

```bash
git commit -m "feat(route): implement route generation"
```

---

# Push a New Branch

Push the feature branch:

```bash
git push -u origin feature/<branch-name>
```

Example:

```bash
git push -u origin feature/route-generation
```

After the first push, subsequent pushes can use:

```bash
git push
```

---

# Complete Feature Workflow

Example: implementing route generation.

```bash
# Switch to development
git switch development

# Get the latest version
git pull origin development

# Create a feature branch
git switch -c feature/route-generation

# Develop
# ...

# Check changes
git status

# Stage changes
git add .

# Commit
git commit -m "feat(route): implement route generation"

# Push
git push -u origin feature/route-generation
```

Then:

```text
feature/route-generation
          ↓
    Pull Request
          ↓
    development
          ↓
 Integration Testing
          ↓
    Pull Request
          ↓
        main
```

---

# Before You Push

Make sure:

* [ ] You are on the correct branch
* [ ] You are not working directly on `main`
* [ ] The branch has a clear purpose
* [ ] There are no API keys or credentials
* [ ] There are no unnecessary files
* [ ] The project builds successfully
* [ ] Relevant tests have been run
* [ ] `git status` has been checked
* [ ] Commit messages follow Conventional Commits
* [ ] There are no unrelated changes
* [ ] The Pull Request targets the correct branch

---

# Why This Strategy?

Lana V2 is intentionally kept simple.

The purpose of this project is not to create a complicated Git workflow. The main goal is to learn how to build an iOS application from the ground up and understand the technical decisions behind it.

The branching strategy therefore follows a simple principle:

> **Keep the Git workflow as simple as the project requires.**

The primary flow is:

```text
feature/*
    ↓
development
    ↓
main
```

`Tech/*` branches are introduced only when a technical problem requires independent experimentation.

This keeps the repository organized while still providing opportunities to practice:

* Feature-based development
* Technical experimentation
* Git branching
* Pull Requests
* Code review
* Integration
* Testing
* Safe merging
* Version control

---

# Important Note

> [!NOTE]
> Lana V2 is a learning project. Not every technical experiment needs to become production code.
>
> A failed technical experiment is still useful if it helps answer a question and leads to a better technical decision.
>
> The goal is not only to make Lana work, but to understand **why** the code is structured and **why** a particular technical approach is chosen.

---

# References

* [Git Documentation](https://git-scm.com/docs)
* [GitHub Documentation](https://docs.github.com/)
* [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
