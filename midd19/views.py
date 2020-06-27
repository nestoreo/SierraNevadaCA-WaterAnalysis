from django.contrib.auth import authenticate,login,logout
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render
from django.urls import reverse
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .forms import SignUpForm,postForm
from .models import Post, Comment
#create views

def index(request):
    if not request.user.is_authenticated:
        return render(request, "midd19/login.html", {'messaged':None})
    context ={"user": request.user}
    return render(request, "midd19/index.html", context)

def chatforum(request):
    context={"posts":Post.objects.all()}
    return render(request, "midd19/chatforum.html", context)

def login_view(request):
    username = request.POST.get("username")
    password = request.POST.get("password")
    user = authenticate(request, username= username, password=password)
    if user is not None:
        login(request, user) #takes a user and logs them into the authentication system.
        return HttpResponseRedirect(reverse("index"))#when redirect, redirect to a url, so reverse takes route from urls.py
    else:
        return render(request, "midd19/login.html", {"message":"Invalid credentials"})

def logout_view(request):
      logout(request)
      return render(request, "midd19/login.html", {"message": "Logged out."})


def register(request):
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            form.save()
            username = form.cleaned_data.get('username')
            raw_password = form.cleaned_data.get('password1')
            user = authenticate(username=username, password=raw_password)#request is optional
            login(request, user)
            return HttpResponseRedirect(reverse("index"))
    else:
        form = SignUpForm()
    return render(request, 'midd19/register.html', {'form': form})

def post(request):
    if request.method=="GET":
        return render(request,'midd19/post.html',{'message':None})
    else:
        content = request.POST.get("content")
        title = request.POST.get("title")
        username=request.user
