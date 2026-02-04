"""CLI Demo for AI Study Planner"""

import:jac from models, Root;
import:jac from auth, register, login;
import:jac from learning, create_path, ai_generate_topics, get_topics, log_session, get_reviews_due, ai_suggest_next, get_stats;

with entry {
    print("=== AI Study Planner Demo ===\n");
    
    root = Root();
    
    # register user
    print("1. Register user...");
    reg_result = root spawn register(username="alex", password="pass123");
    print(f"   {reg_result[0]['status']}\n");
    
    # login
    print("2. Login...");
    login_result = root spawn login(username="alex", password="pass123");
    user = login_result[0]["user"];
    print(f"   Welcome {user.username}!\n");
    
    # create learning path
    print("3. Create learning path...");
    path_result = user spawn create_path(
        name="Machine Learning Fundamentals",
        goal="Master core ML algorithms and concepts"
    );
    path = path_result[0]["path"];
    print(f"   Created path: {path.name}\n");
    
    # AI generate topics
    print("4. AI generating learning topics...");
    gen_result = user spawn ai_generate_topics(path_id=path.id, num_topics=6);
    print(f"   Generated {gen_result[0]['count']} topics:\n");
    
    topics_result = user spawn get_topics(path_id=path.id);
    for topic in topics_result[0]["topics"] {
        prereq_str = "";
        if len(topic["prerequisites"]) > 0 {
            prereq_str = f" (requires: {topic['prerequisites']})";
        }
        print(f"   [{topic['id']}] {topic['title']}");
        print(f"       Difficulty: {topic['difficulty']}, ~{topic['estimated_hours']}h{prereq_str}");
    }
    
    # simulate study sessions
    print("\n5. Simulating study sessions...");
    user spawn log_session(path_id=path.id, topic_id=1, duration=120, quality=4, notes="Good intro");
    print("   Session 1: Topic 1, 2h, quality 4/5");
    
    user spawn log_session(path_id=path.id, topic_id=1, duration=90, quality=5, notes="Mastered basics");
    print("   Session 2: Topic 1, 1.5h, quality 5/5");
    
    user spawn log_session(path_id=path.id, topic_id=2, duration=150, quality=3, notes="Need more practice");
    print("   Session 3: Topic 2, 2.5h, quality 3/5\n");
    
    # get AI suggestion
    print("6. AI suggests next topic...");
    suggest_result = user spawn ai_suggest_next(path_id=path.id);
    if suggest_result[0]["suggestion"] is not None {
        next_topic = suggest_result[0]["suggestion"];
        print(f"   Recommended: {next_topic.title}");
        print(f"   Mastery level: {next_topic.mastery}");
        if next_topic.next_review != "" {
            print(f"   Next review: {next_topic.next_review}");
        }
    }
    
    # check reviews due
    print("\n7. Check reviews due today...");
    review_result = user spawn get_reviews_due(path_id=path.id);
    print(f"   {review_result[0]['count']} topics need review\n");
    
    # get statistics
    print("8. Learning statistics:");
    stats_result = user spawn get_stats(path_id=path.id);
    stats = stats_result[0];
    print(f"   Total topics: {stats['total_topics']}");
    print(f"   Study time: {stats['total_hours']} hours");
    print(f"   Completion: {stats['completion']}%");
    print(f"   Mastery breakdown:");
    print(f"     - Not started: {stats['mastery']['not_started']}");
    print(f"     - Learning: {stats['mastery']['learning']}");
    print(f"     - Practiced: {stats['mastery']['practiced']}");
    print(f"     - Reviewing: {stats['mastery']['reviewing']}");
    print(f"     - Mastered: {stats['mastery']['mastered']}");
    print(f"   Total sessions: {stats['sessions']}");
    
    print("\n=== Demo Complete ===");
    print("\nKey Features Demonstrated:");
    print("✓ AI-generated learning curriculum");
    print("✓ Knowledge graph with prerequisites");
    print("✓ Spaced repetition algorithm (SM-2)");
    print("✓ AI-powered next topic recommendations");
    print("✓ Progress tracking and analytics");
}
