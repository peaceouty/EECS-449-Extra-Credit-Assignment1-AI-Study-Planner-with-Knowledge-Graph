"""CLI Demo for AI Study Planner - Knowledge Graph + SM-2 Spaced Repetition"""

import from models { Path, Topic, Session, User, Difficulty, Mastery, Prerequisite, RelatedTo }
import from datetime { datetime, timedelta }

with entry {
    print("=== AI Study Planner Demo ===\n");

    # --- 1. Create user and connect to root ---
    print("1. Creating user...");
    user = User(
        username="alex",
        password="pass123",
        total_study_hours=0.0,
        streak_days=0,
        next_path_id=1
    );
    root ++> user;
    print(f"   User created: {user.username}\n");

    # --- 2. Create learning path ---
    print("2. Creating learning path...");
    now = datetime.now().strftime("%Y-%m-%d %H:%M");
    path = Path(
        id=1,
        name="Machine Learning Fundamentals",
        goal="Master core ML algorithms and concepts",
        created=now,
        next_topic_id=1,
        next_session_id=1
    );
    user ++> path;
    print(f"   Path: {path.name}\n");

    # --- 3. Build knowledge graph with topics and prerequisite edges ---
    print("3. Building knowledge graph...");

    topics_data = [
        {"title": "Linear Algebra Basics", "desc": "Vectors, matrices, transformations", "diff": Difficulty.BEGINNER, "hours": 3.0},
        {"title": "Probability & Statistics", "desc": "Distributions, Bayes theorem, hypothesis testing", "diff": Difficulty.BEGINNER, "hours": 4.0},
        {"title": "Python for ML", "desc": "NumPy, Pandas, Matplotlib fundamentals", "diff": Difficulty.BEGINNER, "hours": 3.0},
        {"title": "Linear Regression", "desc": "Cost functions, gradient descent, regularization", "diff": Difficulty.INTERMEDIATE, "hours": 4.0},
        {"title": "Classification", "desc": "Logistic regression, SVM, decision trees", "diff": Difficulty.INTERMEDIATE, "hours": 5.0},
        {"title": "Neural Networks", "desc": "Perceptrons, backpropagation, activation functions", "diff": Difficulty.ADVANCED, "hours": 6.0}
    ];

    created_topics: list = [];
    for (i, td) in enumerate(topics_data) {
        t = Topic(
            id=i + 1,
            title=td["title"],
            description=td["desc"],
            difficulty=td["diff"],
            mastery=Mastery.NOT_STARTED,
            estimated_hours=td["hours"],
            actual_hours=0.0,
            review_count=0,
            ease_factor=2.5,
            interval_days=0
        );
        path ++> t;
        created_topics.append(t);
    }

    # Build prerequisite edges (knowledge graph structure)
    # Linear Algebra -> Linear Regression -> Neural Networks
    created_topics[0] +>: Prerequisite(strength=0.9) :+> created_topics[3];
    created_topics[0] +>: Prerequisite(strength=0.7) :+> created_topics[5];
    # Probability -> Classification
    created_topics[1] +>: Prerequisite(strength=0.8) :+> created_topics[4];
    # Python -> Linear Regression, Classification, Neural Networks
    created_topics[2] +>: Prerequisite(strength=1.0) :+> created_topics[3];
    created_topics[2] +>: Prerequisite(strength=1.0) :+> created_topics[4];
    created_topics[2] +>: Prerequisite(strength=0.9) :+> created_topics[5];
    # Linear Regression -> Neural Networks
    created_topics[3] +>: Prerequisite(strength=0.8) :+> created_topics[5];
    # Classification -> Neural Networks (related)
    created_topics[4] +>: RelatedTo(correlation=0.6) :+> created_topics[5];

    for t in created_topics {
        print(f"   [{t.id}] {t.title} ({t.difficulty}) ~{t.estimated_hours}h");
    }
    print(f"   Total: {len(created_topics)} topics with prerequisite edges\n");

    # --- 4. Simulate study sessions with SM-2 algorithm ---
    print("4. Simulating study sessions with SM-2 spaced repetition...\n");

    sessions = [
        {"topic_idx": 0, "duration": 120, "quality": 4, "label": "Linear Algebra - first pass"},
        {"topic_idx": 0, "duration": 90, "quality": 5, "label": "Linear Algebra - review"},
        {"topic_idx": 2, "duration": 100, "quality": 4, "label": "Python for ML - practice"},
        {"topic_idx": 1, "duration": 150, "quality": 3, "label": "Probability - needs work"},
        {"topic_idx": 0, "duration": 60, "quality": 5, "label": "Linear Algebra - mastery check"},
        {"topic_idx": 2, "duration": 80, "quality": 5, "label": "Python for ML - review"},
        {"topic_idx": 3, "duration": 180, "quality": 4, "label": "Linear Regression - intro"},
    ];

    for (sess_i, sess) in enumerate(sessions) {
        topic = created_topics[sess["topic_idx"]];
        quality = sess["quality"];
        duration = sess["duration"];

        # Record session
        s = Session(
            id=sess_i + 1,
            topic_id=topic.id,
            date=datetime.now().strftime("%Y-%m-%d %H:%M"),
            duration=duration,
            quality=quality,
            notes=sess["label"]
        );
        path ++> s;

        # Update topic stats
        topic.actual_hours += duration / 60.0;
        topic.last_reviewed = datetime.now().strftime("%Y-%m-%d %H:%M");
        topic.review_count += 1;

        # === SM-2 Spaced Repetition Algorithm ===
        if quality >= 3 {
            if topic.review_count == 1 {
                topic.interval_days = 1;
            } elif topic.review_count == 2 {
                topic.interval_days = 6;
            } else {
                topic.interval_days = int(float(topic.interval_days) * topic.ease_factor);
            }

            # Update ease factor: EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
            topic.ease_factor = topic.ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
            if topic.ease_factor < 1.3 {
                topic.ease_factor = 1.3;
            }

            # Update mastery level
            if topic.review_count >= 5 and topic.ease_factor > 2.0 {
                topic.mastery = Mastery.MASTERED;
            } elif topic.review_count >= 3 {
                topic.mastery = Mastery.REVIEWING;
            } else {
                topic.mastery = Mastery.PRACTICED;
            }
        } else {
            topic.interval_days = 1;
            topic.review_count = 1;
        }

        next_date = datetime.now() + timedelta(days=topic.interval_days);
        topic.next_review = next_date.strftime("%Y-%m-%d");

        print(f"   Session {sess_i + 1}: {sess['label']}");
        print(f"     Quality: {quality}/5, Next review: {topic.next_review}, EF: {topic.ease_factor}");
    }

    # --- 5. Knowledge graph traversal - find next recommended topic ---
    print("\n5. AI recommendation (graph traversal)...");
    topics = [path -->](`?Topic);
    ready: list = [];
    for topic in topics {
        if topic.mastery == Mastery.MASTERED {
            continue;
        }
        # Check if all prerequisites are met
        prereqs = [topic <--](`?Topic);
        all_met = True;
        for pre in prereqs {
            if pre.mastery != Mastery.MASTERED and pre.mastery != Mastery.REVIEWING {
                all_met = False;
                break;
            }
        }
        if all_met {
            ready.append(topic);
        }
    }

    if len(ready) > 0 {
        best = ready[0];
        for t in ready {
            if t.mastery.value < best.mastery.value {
                best = t;
            }
        }
        print(f"   Recommended next: {best.title}");
        print(f"   Current mastery: {best.mastery}, Reviews: {best.review_count}");
    } else {
        print("   All topics mastered or prerequisites not met!");
    }

    # --- 6. Statistics ---
    print("\n6. Learning statistics:");
    total_hours = 0.0;
    mastery_dist: dict = {"not_started": 0, "learning": 0, "practiced": 0, "reviewing": 0, "mastered": 0};
    for t in created_topics {
        total_hours += t.actual_hours;
        if t.mastery == Mastery.NOT_STARTED {
            mastery_dist["not_started"] += 1;
        } elif t.mastery == Mastery.PRACTICED {
            mastery_dist["practiced"] += 1;
        } elif t.mastery == Mastery.REVIEWING {
            mastery_dist["reviewing"] += 1;
        } elif t.mastery == Mastery.MASTERED {
            mastery_dist["mastered"] += 1;
        }
    }
    mastered_count = mastery_dist["mastered"];
    total = len(created_topics);
    completion = 0.0;
    if total > 0 {
        completion = (mastered_count * 100.0) / total;
    }
    print(f"   Total topics: {total}");
    print(f"   Study time: {int(total_hours * 100) / 100.0} hours");
    print(f"   Completion: {int(completion * 10) / 10.0}%");
    print(f"   Not started: {mastery_dist['not_started']}");
    print(f"   Practiced: {mastery_dist['practiced']}");
    print(f"   Reviewing: {mastery_dist['reviewing']}");
    print(f"   Mastered: {mastery_dist['mastered']}");

    print("\n=== Demo Complete ===");
    print("\nFeatures demonstrated:");
    print("- Knowledge graph with typed nodes and prerequisite edges");
    print("- SM-2 spaced repetition algorithm (ease factor, intervals)");
    print("- Graph traversal for topic recommendations");
    print("- Progress tracking and analytics");
}
