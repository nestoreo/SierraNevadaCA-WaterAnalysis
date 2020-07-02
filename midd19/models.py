from django.db import models
from django.contrib.auth.models import User
from django.urls import reverse


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


    def get_absolute_url_user(self):
        return f"/user/{self.user.username}"

    def get_absolute_url_post(self):
        return f"/user/{self.user.username}/{self.id}"


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
    prime=models.IntegerField(null=True)


    def get_absolute_url_user(self):
        return f"/user/{self.user.username}"
