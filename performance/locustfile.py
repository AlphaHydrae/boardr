from locust import HttpLocust, TaskSet, between

def login(l):
  pass

def logout(l):
  pass

def index(l):
  l.client.get("/api")

class UserBehavior(TaskSet):
  tasks = {index: 1}

  def on_start(self):
    login(self)

  def on_stop(self):
    logout(self)

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(5.0, 9.0)