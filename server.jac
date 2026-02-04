"""Server API walkers"""

import:jac from models, Root;
import:jac from auth, register, login;
import:jac from learning, create_path, ai_generate_topics, add_topic, list_paths, get_topics, log_session, get_reviews_due, ai_suggest_next, get_stats;

glob root = Root();

# register API
walker api_register {
    has username: str;
    has password: str;
    
    can handle with `root entry {
        result = here spawn register(username=self.username, password=self.password);
        report result[0];
    }
}

# login API
walker api_login {
    has username: str;
    has password: str;
    
    can handle with `root entry {
        result = here spawn login(username=self.username, password=self.password);
        report result[0];
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
                result = u spawn create_path(name=self.name, goal=self.goal);
                report result[0];
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# AI generate topics API
walker api_ai_generate {
    has username: str;
    has path_id: int;
    has num_topics: int = 5;
    
    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                result = u spawn ai_generate_topics(path_id=self.path_id, num_topics=self.num_topics);
                report result[0];
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
    has prerequisite_ids: list[int] = [];
    
    can handle with `root entry {
        users = [-->](`?User);
        for u in users {
            if u.username == self.username {
                result = u spawn add_topic(
                    path_id=self.path_id,
                    title=self.title,
                    description=self.description,
                    difficulty=self.difficulty,
                    estimated_hours=self.estimated_hours,
                    prerequisite_ids=self.prerequisite_ids
                );
                report result[0];
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
                result = u spawn list_paths();
                report result[0];
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
                result = u spawn get_topics(path_id=self.path_id);
                report result[0];
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}

# log session API
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
                result = u spawn log_session(
                    path_id=self.path_id,
                    topic_id=self.topic_id,
                    duration=self.duration,
                    quality=self.quality,
                    notes=self.notes
                );
                report result[0];
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
                result = u spawn get_reviews_due(path_id=self.path_id);
                report result[0];
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
                result = u spawn ai_suggest_next(path_id=self.path_id);
                report result[0];
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
                result = u spawn get_stats(path_id=self.path_id);
                report result[0];
                disengage;
            }
        }
        report {"status": "error", "message": "User not found"};
    }
}
