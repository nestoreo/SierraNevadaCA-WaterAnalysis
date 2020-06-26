from django.db import models
from django.contrib.auth.models import Users

class Post(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.CharField(max_length=1000)
    anonymous = models.BooleanField(initial=False)

class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=model.CASCADE)
    comment = models.CharField(max_length=1000)
    anonymous = models.BooleanField(initial=False)
