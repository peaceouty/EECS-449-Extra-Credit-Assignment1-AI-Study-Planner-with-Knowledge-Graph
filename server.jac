"""Server API walkers - REST endpoints via jac serve"""

import from models { User, Path, Topic, Session, Difficulty, Mastery, Prerequisite, RelatedTo }
import from datetime { datetime, timedelta }

# register API
walker api_register {
    has username: str;
    has password: str;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                report {"status": "error", "message": "User exists"};
                disengage;
            }
        }
        new_user = User(
            username=self.username,
            password=self.password,
            total_study_hours=0.0,
            streak_days=0,
            next_path_id=1
        );
        here ++> new_user;
        report {"status": "success", "username": new_user.username};
    }
}

# login API
walker api_login {
    has username: str;
    has password: str;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username and u.password == self.password {
                report {"status": "success", "username": u.username};
                disengage;
            }
        }
        report {"status": "error", "message": "Invalid credentials"};
    }
}

# create path API
walker api_create_path {
    has username: str;
    has name: str;
    has goal: str;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                now = datetime.now().strftime("%Y-%m-%d %H:%M");
                new_path = Path(
                    id=u.next_path_id,
                    name=self.name,
                    goal=self.goal,
                    created=now,
                    next_topic_id=1,
                    next_session_id=1
                );
                u ++> new_path;
                u.next_path_id += 1;
                report {"status": "success", "path_id": new_path.id, "name": new_path.name};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# add topic API
walker api_add_topic {
    has username: str;
    has path_id: int;
    has title: str;
    has description: str = "";
    has difficulty: str = "beginner";
    has estimated_hours: float = 2.0;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        diff_map = {
                            "beginner": Difficulty.BEGINNER,
                            "intermediate": Difficulty.INTERMEDIATE,
                            "advanced": Difficulty.ADVANCED,
                            "expert": Difficulty.EXPERT
                        };
                        diff_val = diff_map.get(self.difficulty.lower(), Difficulty.BEGINNER);
                        new_topic = Topic(
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
                        path ++> new_topic;
                        path.next_topic_id += 1;
                        report {"status": "success", "topic_id": new_topic.id, "title": new_topic.title};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# list paths API
walker api_list_paths {
    has username: str;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                result = [];
                for path in paths {
                    topics = [path -->](`?Topic);
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
                        "topics": len(topics),
                        "mastered": mastered
                    });
                }
                report {"status": "success", "paths": result};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# get topics API
walker api_get_topics {
    has username: str;
    has path_id: int;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        topics = [path -->](`?Topic);
                        result = [];
                        for topic in topics {
                            result.append({
                                "id": topic.id,
                                "title": topic.title,
                                "description": topic.description,
                                "difficulty": str(topic.difficulty),
                                "mastery": str(topic.mastery),
                                "estimated_hours": topic.estimated_hours,
                                "actual_hours": topic.actual_hours,
                                "review_count": topic.review_count,
                                "next_review": topic.next_review
                            });
                        }
                        report {"status": "success", "topics": result};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# log session API (with SM-2)
walker api_log_session {
    has username: str;
    has path_id: int;
    has topic_id: int;
    has duration: int;
    has quality: int;
    has notes: str = "";

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        topics = [path -->](`?Topic);
                        for topic in topics {
                            if topic.id == self.topic_id {
                                now = datetime.now().strftime("%Y-%m-%d %H:%M");
                                new_session = Session(
                                    id=path.next_session_id,
                                    topic_id=self.topic_id,
                                    date=now,
                                    duration=self.duration,
                                    quality=self.quality,
                                    notes=self.notes
                                );
                                path ++> new_session;
                                path.next_session_id += 1;

                                topic.actual_hours += self.duration / 60.0;
                                topic.last_reviewed = now;
                                topic.review_count += 1;

                                # SM-2 algorithm
                                if self.quality >= 3 {
                                    if topic.review_count == 1 {
                                        topic.interval_days = 1;
                                    } elif topic.review_count == 2 {
                                        topic.interval_days = 6;
                                    } else {
                                        topic.interval_days = int(float(topic.interval_days) * topic.ease_factor);
                                    }
                                    topic.ease_factor = topic.ease_factor + (0.1 - (5 - self.quality) * (0.08 + (5 - self.quality) * 0.02));
                                    if topic.ease_factor < 1.3 {
                                        topic.ease_factor = 1.3;
                                    }
                                    if topic.review_count >= 5 and topic.ease_factor > 2.0 {
                                        topic.mastery = Mastery.MASTERED;
                                    } elif topic.review_count >= 3 {
                                        topic.mastery = Mastery.REVIEWING;
                                    } elif topic.review_count >= 1 {
                                        topic.mastery = Mastery.PRACTICED;
                                    }
                                } else {
                                    topic.interval_days = 1;
                                    topic.review_count = 1;
                                }
                                next_date = datetime.now() + timedelta(days=topic.interval_days);
                                topic.next_review = next_date.strftime("%Y-%m-%d");
                                u.total_study_hours += self.duration / 60.0;

                                report {"status": "success", "next_review": topic.next_review, "mastery": str(topic.mastery)};
                                disengage;
                            }
                        }
                        report {"status": "error", "message": "Topic not found"};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# get reviews due API
walker api_reviews_due {
    has username: str;
    has path_id: int;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        topics = [path -->](`?Topic);
                        today = datetime.now().strftime("%Y-%m-%d");
                        due = [];
                        for topic in topics {
                            if topic.next_review != "" and topic.next_review <= today and topic.mastery != Mastery.MASTERED {
                                due.append({
                                    "id": topic.id,
                                    "title": topic.title,
                                    "review_count": topic.review_count
                                });
                            }
                        }
                        report {"status": "success", "due": due, "count": len(due)};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# AI suggest next API
walker api_suggest_next {
    has username: str;
    has path_id: int;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        topics = [path -->](`?Topic);
                        ready: list = [];
                        for topic in topics {
                            if topic.mastery == Mastery.MASTERED {
                                continue;
                            }
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
                        if len(ready) == 0 {
                            report {"status": "success", "suggestion": None};
                            disengage;
                        }
                        best = ready[0];
                        for t in ready {
                            if t.mastery.value < best.mastery.value {
                                best = t;
                            }
                        }
                        report {"status": "success", "suggestion": {"id": best.id, "title": best.title, "mastery": str(best.mastery)}};
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# get stats API
walker api_get_stats {
    has username: str;
    has path_id: int;

    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                paths = [u -->](`?Path);
                for path in paths {
                    if path.id == self.path_id {
                        topics = [path -->](`?Topic);
                        sessions = [path -->](`?Session);
                        total_hours = 0.0;
                        mastery_dist: dict = {"not_started": 0, "learning": 0, "practiced": 0, "reviewing": 0, "mastered": 0};
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
                        total = len(topics);
                        completion = 0.0;
                        if total > 0 {
                            completion = (mastery_dist["mastered"] * 100.0) / total;
                        }
                        report {
                            "status": "success",
                            "total_topics": total,
                            "total_hours": int(total_hours * 100) / 100.0,
                            "completion": int(completion * 10) / 10.0,
                            "mastery": mastery_dist,
                            "sessions": len(sessions)
                        };
                        disengage;
                    }
                }
                report {"status": "error", "message": "Path not found"};
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}
