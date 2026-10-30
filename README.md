# TravelMate

TravelMate is a Flutter application designed to help users plan, organize, and manage their trips.

This repository contains the shared Flutter starter project, application architecture, and team development workflow.

---

# 1. Team Responsibilities and File Assignments

Each team member is primarily responsible for implementing and maintaining their assigned files. Everyone can access and use the other files, but coordinate with the relevant owner before modifying shared code or another person's files.

| Team Member | Responsibilities | Assigned Files |
|---|---|---|
| **Person 1 (Z)** | Home & Trip Dashboard | `home_screen.dart`, `trip_dashboard_screen.dart` |
| **Person 2 (Se)** | Trip Creation & Itinerary | `create_trip_screen.dart`, `itinerary_screen.dart` |
| **Person 3 (N)** | Architecture, Navigation & Shared Models | `main.dart`, `routes.dart`, `main_shell.dart`, and all five shared models |
| **Person 4 (SR)** | Storage & Settings | `trip_service.dart`, `settings_screen.dart` |
| **Person 5 (M)** | Packing & Expenses | `packing_screen.dart`, `expenses_screen.dart` |
| **Person 6 (F)** | Places, Maps & Notifications | `places_screen.dart`, `notification_service.dart` (new file) |

### Shared Files

The following files are shared components of the application:

- `models/`: Contains the five shared data models used throughout the application.
- `routes.dart`: Defines application route names and navigation between screens. Coordinate with Person 3 before modifying.
- `trip_service.dart`: Manages shared trip data. Coordinate with Person 4 before modifying its methods or data handling.
- `placeholder_screen.dart`: Provides a temporary reusable screen layout while individual screens are being developed.

---

# 2. Dart File Documentation Comments

Before implementing your assigned functionality, add a short descriptive comment at the very top of each Dart file you own.

Each comment should identify:

1. The file name.
2. The purpose and responsibility of the file.
3. The team member responsible for maintaining it.

Use the following format:

```dart
// File: home_screen.dart
// Purpose: Displays the user's trips and provides navigation
// to create or open a trip.
// Owner: Person 1 (Z).
```

### Guidelines

- Keep descriptions concise (approximately 2–3 lines).
- Use the correct file name and owner.
- Preserve existing useful comments, including `OWNER` comments.
- Update existing ownership comments if necessary.
- Add comments to all Dart files you are responsible for, not just your main screen.

For shared files, use:

```dart
// Owner: Shared – maintained by the team.
```

Do not add documentation comments to generated Flutter files or third-party packages.

---

# 3. Getting Started

### Step 1: Clone the Repository

Clone the TravelMate repository to your local machine:

```bash
git clone https://github.com/nabihaaaa/TravelMate.git
```

Navigate into the project directory:

```bash
cd TravelMate
```

### Step 2: Switch to the Development Branch

The team works from the `dev` branch rather than directly from `main`.

```bash
git checkout dev
git pull origin dev
```

### Step 3: Install Dependencies

From the project root directory (where `pubspec.yaml` is located), run:

```bash
flutter pub get
```

### Step 4: Run the Application

```bash
flutter run
```

Make sure the application launches successfully before beginning development.

---

# 4. GitHub Branching Strategy

We use three levels of branches to organize development and prevent unfinished code from affecting the stable application.

| Branch | Purpose |
|---|---|
| `main` | Stable, tested version of the application. |
| `dev` | Shared development branch where completed features are integrated and tested. |
| Feature branches | Individual branches where team members implement their assigned functionality. |

### Creating Your Feature Branch

Everyone must create their own feature branch from `dev`.

First, switch to `dev` and retrieve the latest changes:

```bash
git checkout dev
git pull origin dev
```

Create a new feature branch using the following naming convention:

```bash
git checkout -b feature/yourname-yourfeature
```

Examples:

```text
feature/person1-home
feature/person2-itinerary
feature/person3-navigation
feature/person4-storage
feature/person5-packing
feature/person6-places
```

Each team member should use a unique branch name.

---

# 5. Submitting Your Work

Once you have completed and tested your assigned functionality, commit and push your changes to your feature branch.

### Step 1: Stage Your Changes

```bash
git add .
```

### Step 2: Commit Your Changes

Use a descriptive commit message:

```bash
git commit -m "Implement home screen"
```

### Step 3: Push Your Feature Branch

```bash
git push -u origin your-branch-name
```

Replace `your-branch-name` with your actual feature branch name.

### Step 4: Create a Pull Request

On GitHub:

1. Open the TravelMate repository.
2. Navigate to **Pull Requests**.
3. Select **New Pull Request**.
4. Set the **base branch** to `dev`.
5. Set the **compare branch** to your feature branch.
6. Create the Pull Request and briefly describe your changes.

The project coordinator will review the changes and merge approved Pull Requests into `dev`.

**Important:** Do not merge directly into `main`. The `dev` branch will only be merged into `main once the integrated application has been tested and is working correctly.

---

# 6. Keeping Your Branch Updated

Before starting each work session, retrieve the latest changes from `dev`.

```bash
git checkout dev
git pull origin dev
```

Then return to your feature branch:

```bash
git checkout your-branch-name
```

To incorporate the latest development changes into your feature branch:

```bash
git merge dev
```

Resolve any merge conflicts before continuing development.

If you have uncommitted changes, commit or safely set them aside before switching branches or merging.

---

# 7. Important Team Guidelines

All team members should follow these guidelines throughout development:

- **Branching:** Do not push directly to `main` or `dev`. Work on your own feature branch and submit a Pull Request into `dev`.
- **File Ownership:** Work primarily on your assigned files. Coordinate with the relevant owner before modifying another person's files.
- **Shared Models:** Coordinate with Person 3 before modifying shared data models.
- **Navigation:** Coordinate with Person 3 before changing route names, screen constructors, or navigation arguments.
- **Storage:** Coordinate with Person 4 before changing shared storage functionality or `trip_service.dart`.
- **Communication:** Notify the relevant team member if you need to modify shared files.
- **Testing:** Test your changes before submitting a Pull Request.
- **Commits:** Use clear, descriptive commit messages.
- **Updates:** Pull the latest `dev` branch before starting each work session.
- **Integration:** Report merge conflicts, errors, or integration problems to the project coordinator.

---

# 8. Project Structure

The current Flutter project is organized as follows:

```text
travelmate/
│
├── lib/
│   ├── main.dart
│   ├── routes.dart
│   │
│   ├── models/
│   │   ├── trip.dart
│   │   ├── itinerary_item.dart
│   │   ├── packing_item.dart
│   │   ├── expense.dart
│   │   └── place.dart
│   │
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── trip_dashboard_screen.dart
│   │   ├── create_trip_screen.dart
│   │   ├── itinerary_screen.dart
│   │   ├── packing_screen.dart
│   │   ├── expenses_screen.dart
│   │   ├── places_screen.dart
│   │   ├── settings_screen.dart
│   │   └── main_shell.dart
│   │
│   ├── services/
│   │   ├── trip_service.dart
│   │   └── notification_service.dart
│   │
│   └── widgets/
│       └── placeholder_screen.dart
│
├── android/
├── ios/
├── web/
├── test/
│
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── .gitignore
```

---

# 9. Additional Project Notes

- **Trip Budget:** An optional `budget` field was added to the `Trip` model to support the Expenses feature. This field is additional to the original proposal UML and should be mentioned in the project write-up.
- **Data Models:** The starter project currently includes five models: `Trip`, `ItineraryItem`, `PackingItem`, `Expense`, and `Place`.
- **Additional Models:** `SafetyCheckIn` and `TrustedContact` are not currently included.
- **Navigation:** The application uses Flutter's standard named-route navigation mechanisms, including `Navigator.pushNamed` and `onGenerateRoute`.
- **State Management:** The starter project uses `setState` and a shared `TripService`. The storage implementation can be updated while maintaining the agreed method interfaces.

