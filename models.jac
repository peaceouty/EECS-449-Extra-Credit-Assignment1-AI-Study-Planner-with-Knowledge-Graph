"""AI Study Planner - Knowledge Graph Data Models"""

import from byllm.lib { Model }
import from datetime { datetime, timedelta }

glob llm = Model(model_name="gpt-4o-mini");

# difficulty levels
enum Difficulty {
    BEGINNER = "beginner",
    INTERMEDIATE = "intermediate",
    ADVANCED = "advanced",
    EXPERT = "expert"
}

# mastery status
enum Mastery {
    NOT_STARTED = 0,
    LEARNING = 1,
    PRACTICED = 2,
    REVIEWING = 3,
    MASTERED = 4
}

# knowledge topic node
node Topic {
    has id: int;
    has title: str;
    has description: str = "";
    has difficulty: Difficulty = Difficulty.BEGINNER;
    has mastery: Mastery = Mastery.NOT_STARTED;
    has estimated_hours: float = 2.0;
    has actual_hours: float = 0.0;
    has review_count: int = 0;
    has last_reviewed: str = "";
    has next_review: str = "";
    has ease_factor: float = 2.5;
    has interval_days: int = 0;
}

# prerequisite edge with strength
edge Prerequisite {
    has strength: float = 1.0;
}

# related concept edge
edge RelatedTo {
    has correlation: float = 0.5;
}

# study session tracker
node Session {
    has id: int;
    has topic_id: int;
    has date: str;
    has duration: int;
    has quality: int = 3;
    has notes: str = "";
}

# learning path container
node Path {
    has id: int;
    has name: str;
    has goal: str;
    has created: str;
    has next_topic_id: int = 1;
    has next_session_id: int = 1;
}

# user node
node User {
    has username: str;
    has password: str;
    has total_study_hours: float = 0.0;
    has streak_days: int = 0;
    has next_path_id: int = 1;
}

node Root {}
