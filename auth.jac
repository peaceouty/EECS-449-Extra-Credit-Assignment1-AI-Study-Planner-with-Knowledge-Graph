"""Authentication walkers"""

import:jac from models, User, Root;

walker register {
    has username: str;
    has password: str;
    
    can signup with Root entry {
        users = [-->];
        for u in users {
            if u.username == self.username {
                report {"status": "error", "message": "User exists"};
                disengage;
            }
        }
        new_user = here ++> User(
            username=self.username,
            password=self.password,
            total_study_hours=0.0,
            streak_days=0,
            next_path_id=1
        );
        report {"status": "success", "user": new_user};
    }
}

walker login {
    has username: str;
    has password: str;
    
    can auth with Root entry {
        users = [-->];
        for u in users {
            if u.username == self.username and u.password == self.password {
                report {"status": "success", "user": u};
                disengage;
            }
        }
        report {"status": "error", "message": "Invalid credentials"};
    }
}
