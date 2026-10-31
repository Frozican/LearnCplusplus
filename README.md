# Learn C++

A free browser-based C++ learning platform with a Basic Course and an Advanced Course.

## Features

- 10 beginner lessons and 11 advanced lessons
- Explanations, code examples, tips, and knowledge checks
- Searchable lesson library
- Local progress tracking and XP
- Responsive desktop and mobile layout
- No account, backend, framework, or build step required

## GitHub Pages

1. Open **Settings → Pages**.
2. Set the deployment source to **GitHub Actions**.
3. The workflow in `.github/workflows/pages.yml` deploys on pushes to `main`; it can also be started manually in Actions.

## Structure

- `assets/css/main.css` — site styling
- `assets/js/app.js` — application startup and event wiring
- `assets/js/navigation.js` — dashboard, course navigation, and lesson rendering
- `assets/js/progress.js` — progress state, XP, and local storage
- `assets/js/quiz.js` — quiz checking and lesson completion
- `assets/js/search.js` — lesson search
- `assets/js/lessons/basic.js` and `advanced.js` — separate course content

Progress is stored in local storage. The site teaches through explanations, examples, and quizzes; it does not execute C++ code in the browser.
