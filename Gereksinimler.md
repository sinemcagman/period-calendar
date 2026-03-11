Role: You are a Senior Mobile App Developer expert in Flutter/Dart, local storage, state management, and background processes.
Task: Develop the architecture, logic, and functional code for a comprehensive Menstrual Cycle Tracking application based on the provided UI designs.
Language Constraint: The codebase will be in English, but absolutely all visible UI strings, alerts, and notifications must be hardcoded or localized in **Turkish**.

Technical Requirements & Logic Specifications:

1. State & Theme Management:
   - Implement dynamic theming supporting both Light Mode and Dark Mode (using deep greys/blacks combined with Pink/Red primary colors).
   - Use a robust state management solution to handle UI updates across screens.

2. Local Storage (SQLite):
   - Use `sqflite` for 100% offline, on-device data storage.
   - Required Tables: `Users` (name, preferences, theme), `Cycles` (start_date, end_date), `DailyLogs` (date, mood_type, physical_symptoms), `WaterIntake` (date, amount), `Inventory` (item_type, current_stock), `Reminders` (text, trigger_time).
   - Pre-seed a `BlogPosts` table with offline health tips (e.g., nutrition, cramp relief).

3. Core Algorithms:
   - Scientific Ovulation: Predict ovulation window (14 days before next expected period).
   - Custom Gap Calculation: Calculate the exact number of days between the *end* date of the previous period and the *start* date of the next period. Display as "Döngü günü: X gün".
   
4. Features & Widgets:
   - Onboarding: Ask for the user's name on first launch, save to local storage, and never show again. Ensure the layout is perfectly centered.
   - Main Dashboard Animation: Implement a custom top-screen dripping animation (using an AnimationController or a custom painter) visible ONLY when the current date is within the logged period days.
   - Water Tracker: A daily reset counter to track water glasses consumed.
   - Hygiene Inventory: Decrease the stock counter manually or automatically (based on period days). Trigger a local warning ("Stok tükeniyor, alışveriş zamanı") when stock hits a defined threshold.
   - Statistics: Integrate the `fl_chart` package. Aggregate data from SQLite to render a Line Chart (last 6 months cycle lengths) and Pie Charts (most frequent moods and physical symptoms).

5. Notifications (`flutter_local_notifications`):
   - Schedule an automatic push notification exactly 2 days before the predicted start date of the next period.
   - Support custom user-created reminders based on time triggers.

USE design FOLDER FOR UI DESIGNS