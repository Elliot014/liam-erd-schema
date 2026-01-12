CREATE TABLE users (
  id INT,
  email VARCHAR(255),
  full_name VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE organizations (
  id INT,
  name VARCHAR(255),
  PRIMARY KEY (id)
);

CREATE TABLE memberships (
  id INT,
  user_id INT,
  organization_id INT,
  role VARCHAR(50),
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

CREATE TABLE projects (
  id INT,
  organization_id INT,
  name VARCHAR(255),
  description TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (organization_id) REFERENCES organizations(id)
);

CREATE TABLE tasks (
  id INT,
  project_id INT,
  title VARCHAR(255),
  status VARCHAR(30),
  assignee_id INT,
  due_date DATE,
  PRIMARY KEY (id),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (assignee_id) REFERENCES users(id)
);

CREATE TABLE task_comments (
  id INT,
  task_id INT,
  author_id INT,
  body TEXT,
  PRIMARY KEY (id),
  FOREIGN KEY (task_id) REFERENCES tasks(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);
