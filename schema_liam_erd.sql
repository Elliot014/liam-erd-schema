-- schema_liam_erd.sql (parser-friendly, ERD-focused)

CREATE TABLE users (
  id INT NOT NULL,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (email)
);

CREATE TABLE organizations (
  id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (name)
);

CREATE TABLE memberships (
  id INT NOT NULL,
  user_id INT NOT NULL,
  organization_id INT NOT NULL,
  role VARCHAR(50),
  PRIMARY KEY (id),
  UNIQUE (user_id, organization_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_memberships_org_id  ON memberships(organization_id);

CREATE TABLE projects (
  id INT NOT NULL,
  organization_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  PRIMARY KEY (id),
  UNIQUE (organization_id, name),
  FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

CREATE INDEX idx_projects_org_id ON projects(organization_id);

CREATE TABLE tasks (
  id INT NOT NULL,
  project_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  status VARCHAR(30),
  assignee_id INT,
  due_date DATE,
  PRIMARY KEY (id),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (assignee_id) REFERENCES users(id)
);

CREATE INDEX idx_tasks_project_id  ON tasks(project_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);

CREATE TABLE task_comments (
  id INT NOT NULL,
  task_id INT NOT NULL,
  author_id INT NOT NULL,
  body TEXT NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (task_id) REFERENCES tasks(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE INDEX idx_task_comments_task_id   ON task_comments(task_id);
CREATE INDEX idx_task_comments_author_id ON task_comments(author_id);
