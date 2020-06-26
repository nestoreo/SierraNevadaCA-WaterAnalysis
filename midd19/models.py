from django.db import models
from django.contrib.auth.models import User

class Post(models.Model):
    title = models.CharField(max_length=100)
    comment_count=models.IntegerField(default=0)
    time=models.DateTimeField(auto_now_add=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.CharField(max_length=1000)
    anonymous = models.BooleanField(default=False)
    likes=models.IntegerField(default=0)
    dislikes=models.IntegerField(default=0)

class Comment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    comment = models.CharField(max_length=1000)
    anonymous = models.BooleanField(default=False)
    likes=models.IntegerField(default=0)
    dislikes=models.IntegerField(default=0)
