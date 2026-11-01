# Learn C++

A free, structured C++ learning platform with **1,000 lessons across 100 chapters**, optional chapter tests, progress analytics, and optional Supabase accounts.

## Features
- 500 Basic Course lessons and 500 Advanced Course lessons
- 100 chapters with 10 lessons each
- A knowledge check in every lesson
- Optional 5-question chapter tests
- Progress, XP, strengths, weaknesses, and revision suggestions
- Supabase email/password authentication and cloud progress sync
- Local progress fallback when Supabase is not configured
- Responsive interface and no build step for GitHub Pages

## GitHub Pages
In Settings → Pages, choose GitHub Actions. The included workflow deploys the repository root on every push to main.

## Configure Supabase
1. Create a Supabase project.
2. In Project Settings → API, copy the Project URL and public anon/publishable key.
3. Set SUPABASE_URL and SUPABASE_ANON_KEY in assets/js/config.js.
4. Run the complete SQL script in supabase/schema.sql using Supabase SQL Editor.
5. In Authentication → URL Configuration, add https://frozican.github.io/LearnCplusplus/ to allowed redirect URLs.
6. Configure email confirmation and SMTP in Supabase Auth as desired.

Only the public anon/publishable key belongs in the browser. Never expose a service_role key. Row Level Security is enabled for user data.

Without Supabase credentials, lessons and local progress work, but registration and cloud sync are disabled.

## Structure
- index.html — application shell
- assets/css/app.css — responsive interface
- assets/js/app.js — UI, navigation, lessons, tests, dashboards
- assets/js/data/curriculum.js — 1,000 lessons and chapter test bank
- assets/js/config.js — public Supabase configuration
- assets/js/supabase.js — Supabase client
- assets/js/auth.js — sign-up, sign-in, sign-out, password reset
- assets/js/progress.js — local/cloud progress and skill analysis
- supabase/schema.sql — tables, indexes, trigger, and RLS policies

## Curriculum
**Basic:** C++ Foundations; Variables, Types & Expressions; Input, Output & Formatting; Decisions & Boolean Logic; Loops & Iteration; Functions & Program Structure; Arrays, Strings & Collections; References, Pointers & Memory; Structs, Enums & User-Defined Types; Classes & Object-Oriented Basics.

**Advanced:** Object-Oriented Design; STL Containers & Iterators; Algorithms, Lambdas & Ranges; Templates & Generic Programming; Resource Management & RAII; Modern C++ Features; Errors, Exceptions & Debugging; Files, Modules & Build Systems; Data Structures & Algorithms; Concurrency, Performance & Projects.

## Notes
The platform teaches with explanations, examples, practice prompts, and quizzes. It does not yet compile or execute submitted C++ code in the browser. Skill insights are based on quiz attempts and become more meaningful with more answers.