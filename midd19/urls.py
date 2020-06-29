from django.urls import path
from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("login", views.login_view, name="login"),
    path("logout", views.logout_view, name="logout"),
    #path("userdetails", views.user_details, name="user_details"),
    path("register", views.register, name="register"),
    path("chatforum", views.chatforum, name="chatforum"),
]
