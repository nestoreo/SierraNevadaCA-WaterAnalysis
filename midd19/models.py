from django.db import models
from django.contrib.auth.models import User
<<<<<<< HEAD
from django.urls import reverse
=======
>>>>>>> 7c95fe794f3fd199c981babfa6d2ee61d5f5f86e

class Post(models.Model):
    #input
    title = models.CharField(max_length=100)
    content = models.CharField(max_length=1000)
    anonymous = models.BooleanField(default=False)

    #automatic
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    comment_count=models.IntegerField(default=0)
    time=models.DateTimeField(auto_now_add=True)
    likes=models.IntegerField(default=0)
    dislikes=models.IntegerField(default=0)



class Comment(models.Model):
    #input
    comment = models.CharField(max_length=1000)
    anonymous = models.BooleanField(default=False)

    #automatic
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    likes=models.IntegerField(default=0)
    dislikes=models.IntegerField(default=0)
    time=models.DateTimeField(auto_now_add=True)
