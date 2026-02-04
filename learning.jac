"""Learning path and topic management walkers"""

import:jac from models, Path, Topic, Session, User, Difficulty, Mastery, Prerequisite, RelatedTo, llm;
import:py from datetime, datetime, timedelta;

# create new learning path
walker create_path {
    has name: str;
    has goal: str;
    
    can create with User entry {
        paths = [-->];
        now = datetime.now().strftime("%Y-%m-%d %H:%M");
        new_path = here ++> Path(
            id=here.next_path_id,
            name=self.name,
            goal=self.goal,
            created=now,
            next_topic_id=1,
            next_session_id=1
        );
        here.next_path_id += 1;
        report {"status": "success", "path": new_path};
    }
}

# AI-generate learning topics for a path
walker ai_generate_topics {
    has path_id: int;
    has num_topics: int = 5;
    
    can generate with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                # AI generates structured topic breakdown
                topics_data: list[dict] = [] by llm(
                    reason=True,
                    incl_info=(
                        f"Generate {self.num_topics} learning topics for: {path.goal}. "
                        "Each topic should have: title (str), description (str), difficulty (beginner/intermediate/advanced/expert), estimated_hours (float). "
                        "Order from foundational to advanced."
                    )
                );
                
                created_topics = [];
                prev_topic = None;
                
                for i, topic_dict in enumerate(topics_data) {
                    if i >= self.num_topics { break; }
                    
                    # map difficulty
                    diff_str = topic_dict.get("difficulty", "beginner").lower();
                    diff_map = {
                        "beginner": Difficulty.BEGINNER,
                        "intermediate": Difficulty.INTERMEDIATE,
                        "advanced": Difficulty.ADVANCED,
                        "expert": Difficulty.EXPERT
                    };
                    diff_val = diff_map.get(diff_str, Difficulty.BEGINNER);
                    
                    new_topic = path ++> Topic(
                        id=path.next_topic_id,
                        title=topic_dict.get("title", f"Topic {i+1}"),
                        description=topic_dict.get("description", ""),
                        difficulty=diff_val,
                        mastery=Mastery.NOT_STARTED,
                        estimated_hours=float(topic_dict.get("estimated_hours", 2.0)),
                        actual_hours=0.0,
                        review_count=0,
                        ease_factor=2.5,
                        interval_days=0
                    );
                    path.next_topic_id += 1;
                    
                    # create prerequisite chain
                    if prev_topic is not None {
                        prev_topic +[Prerequisite(strength=0.9)]->+ new_topic;
                    }
                    
                    prev_topic = new_topic;
                    created_topics.append(new_topic);
                }
                
                report {"status": "success", "topics": created_topics, "count": len(created_topics)};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# add topic manually
walker add_topic {
    has path_id: int;
    has title: str;
    has description: str = "";
    has difficulty: str = "beginner";
    has estimated_hours: float = 2.0;
    has prerequisite_ids: list[int] = [];
    
    can add with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                diff_map = {
                    "beginner": Difficulty.BEGINNER,
                    "intermediate": Difficulty.INTERMEDIATE,
                    "advanced": Difficulty.ADVANCED,
                    "expert": Difficulty.EXPERT
                };
                diff_val = diff_map.get(self.difficulty.lower(), Difficulty.BEGINNER);
                
                new_topic = path ++> Topic(
                    id=path.next_topic_id,
                    title=self.title,
                    description=self.description,
                    difficulty=diff_val,
                    mastery=Mastery.NOT_STARTED,
                    estimated_hours=self.estimated_hours,
                    actual_hours=0.0,
                    review_count=0,
                    ease_factor=2.5,
                    interval_days=0
                );
                path.next_topic_id += 1;
                
                # link prerequisites
                topics = [path -->];
                for topic in topics {
                    if topic.id in self.prerequisite_ids {
                        topic +[Prerequisite(strength=1.0)]->+ new_topic;
                    }
                }
                
                report {"status": "success", "topic": new_topic};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# list all paths
walker list_paths {
    can list with User entry {
        paths = [-->];
        result = [];
        for path in paths {
            topics = [path -->];
            topic_count = len(topics);
            mastered = 0;
            for t in topics {
                if t.mastery == Mastery.MASTERED {
                    mastered += 1;
                }
            }
            result.append({
                "id": path.id,
                "name": path.name,
                "goal": path.goal,
                "created": path.created,
                "topics": topic_count,
                "mastered": mastered
            });
        }
        report {"paths": result};
    }
}

# get topics in a path
walker get_topics {
    has path_id: int;
    
    can get with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                topics = [path -->];
                result = [];
                for topic in topics {
                    # get prerequisites
                    prereqs = [];
                    incoming = [--> topic];
                    for pre in incoming {
                        prereqs.append(pre.id);
                    }
                    
                    result.append({
                        "id": topic.id,
                        "title": topic.title,
                        "description": topic.description,
                        "difficulty": topic.difficulty,
                        "mastery": topic.mastery,
                        "estimated_hours": topic.estimated_hours,
                        "actual_hours": topic.actual_hours,
                        "review_count": topic.review_count,
                        "next_review": topic.next_review,
                        "prerequisites": prereqs
                    });
                }
                report {"status": "success", "topics": result};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# log study session with spaced repetition
walker log_session {
    has path_id: int;
    has topic_id: int;
    has duration: int;
    has quality: int;
    has notes: str = "";
    
    can log with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                topics = [path -->];
                for topic in topics {
                    if topic.id == self.topic_id {
                        # create session
                        now = datetime.now().strftime("%Y-%m-%d %H:%M");
                        new_session = path ++> Session(
                            id=path.next_session_id,
                            topic_id=self.topic_id,
                            date=now,
                            duration=self.duration,
                            quality=self.quality,
                            notes=self.notes
                        );
                        path.next_session_id += 1;
                        
                        # update topic
                        topic.actual_hours += self.duration / 60.0;
                        topic.last_reviewed = now;
                        topic.review_count += 1;
                        
                        # SM-2 spaced repetition algorithm
                        if self.quality >= 3 {
                            if topic.review_count == 1 {
                                topic.interval_days = 1;
                            } elif topic.review_count == 2 {
                                topic.interval_days = 6;
                            } else {
                                topic.interval_days = int(topic.interval_days * topic.ease_factor);
                            }
                            
                            topic.ease_factor = topic.ease_factor + (0.1 - (5 - self.quality) * (0.08 + (5 - self.quality) * 0.02));
                            if topic.ease_factor < 1.3 {
                                topic.ease_factor = 1.3;
                            }
                            
                            # update mastery
                            if topic.review_count >= 5 and topic.ease_factor > 2.0 {
                                topic.mastery = Mastery.MASTERED;
                            } elif topic.review_count >= 3 {
                                topic.mastery = Mastery.REVIEWING;
                            } elif topic.review_count >= 1 {
                                topic.mastery = Mastery.PRACTICED;
                            } else {
                                topic.mastery = Mastery.LEARNING;
                            }
                        } else {
                            # quality < 3, restart
                            topic.interval_days = 1;
                            topic.review_count = 1;
                        }
                        
                        # calculate next review
                        next_date = datetime.now() + timedelta(days=topic.interval_days);
                        topic.next_review = next_date.strftime("%Y-%m-%d");
                        
                        # update user stats
                        here.total_study_hours += self.duration / 60.0;
                        
                        report {"status": "success", "topic": topic, "next_review": topic.next_review};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Topic not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# get today's review topics
walker get_reviews_due {
    has path_id: int;
    
    can check with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                topics = [path -->];
                today = datetime.now().strftime("%Y-%m-%d");
                due_topics = [];
                
                for topic in topics {
                    if topic.next_review != "" and topic.next_review <= today and topic.mastery != Mastery.MASTERED {
                        due_topics.append({
                            "id": topic.id,
                            "title": topic.title,
                            "review_count": topic.review_count,
                            "last_reviewed": topic.last_reviewed
                        });
                    }
                }
                
                report {"status": "success", "due": due_topics, "count": len(due_topics)};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# AI suggest next topic to study
walker ai_suggest_next {
    has path_id: int;
    
    can suggest with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                topics = [path -->];
                
                # find ready topics (prerequisites met)
                ready = [];
                for topic in topics {
                    if topic.mastery == Mastery.MASTERED {
                        continue;
                    }
                    
                    prereqs = [--> topic];
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
                
                if len(ready) == 0 {
                    report {"status": "success", "suggestion": None, "message": "No topics ready"};
                    disengage;
                }
                
                # prioritize by review schedule and mastery
                best = ready[0];
                for topic in ready {
                    if topic.mastery < best.mastery {
                        best = topic;
                    } elif topic.mastery == best.mastery {
                        if topic.next_review != "" and (best.next_review == "" or topic.next_review < best.next_review) {
                            best = topic;
                        }
                    }
                }
                
                report {"status": "success", "suggestion": best};
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}

# get learning statistics
walker get_stats {
    has path_id: int;
    
    can analyze with User entry {
        paths = [-->];
        for path in paths {
            if path.id == self.path_id {
                topics = [path -->];
                sessions = [path -->];
                
                total_topics = len(topics);
                total_hours = 0.0;
                mastery_dist = {
                    "not_started": 0,
                    "learning": 0,
                    "practiced": 0,
                    "reviewing": 0,
                    "mastered": 0
                };
                
                for topic in topics {
                    total_hours += topic.actual_hours;
                    if topic.mastery == Mastery.NOT_STARTED {
                        mastery_dist["not_started"] += 1;
                    } elif topic.mastery == Mastery.LEARNING {
                        mastery_dist["learning"] += 1;
                    } elif topic.mastery == Mastery.PRACTICED {
                        mastery_dist["practiced"] += 1;
                    } elif topic.mastery == Mastery.REVIEWING {
                        mastery_dist["reviewing"] += 1;
                    } elif topic.mastery == Mastery.MASTERED {
                        mastery_dist["mastered"] += 1;
                    }
                }
                
                completion = 0.0;
                if total_topics > 0 {
                    completion = (mastery_dist["mastered"] / total_topics) * 100;
                }
                
                report {
                    "status": "success",
                    "total_topics": total_topics,
                    "total_hours": round(total_hours, 2),
                    "completion": round(completion, 1),
                    "mastery": mastery_dist,
                    "sessions": len(sessions)
                };
                disengage;
            }
        }
        report {"status": "error", "message": "Path not found"};
    }
}
