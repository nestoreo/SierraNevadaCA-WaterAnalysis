from django.contrib.auth import authenticate,login,logout
from django.http import HttpResponse, HttpResponseRedirect, JsonResponse
from django.shortcuts import render
from django.urls import reverse
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .forms import SignUpForm,PostForm, CommentForm
from .models import Post, Comment
from django.contrib.auth.models import User


#create views
def index(request):
    if not request.user.is_authenticated:
        return render(request, "midd19/login.html", {'messaged':None})
    context ={"user": request.user}
    return render(request, "midd19/index.html", context)

def chatforum(request):
    liked_posts_displayed = 3; #number of liked and uliked posts displayed
    posts_displayed = 10; #number of posts displayed on the page(!including liked/unliked)
    #get most liked Posts
    most_liked = Post.objects.all().order_by('-likes')[:liked_posts_displayed]
    least_liked = Post.objects.all().order_by('-dislikes')[:liked_posts_displayed]
    posts = Post.objects.all()[:posts_displayed]

    if request.method == "POST":
        form = PostForm(request.POST)
        if form.is_valid():
            title = form.cleaned_data.get("title")
            content = form.cleaned_data.get('content')
            anonymous = form.cleaned_data.get('anonymous')
            username = request.user
            post = Post(title=title,content=content,anonymous=anonymous,user=request.user)
            post.save()
            return HttpResponseRedirect(reverse('chatforum'))
    else:
        form = PostForm()
    return render(request,'midd19/chatforum.html',{'form':form, "posts": posts, "most_liked": most_liked, "least_liked": least_liked})






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



def user_view(request, username):
    user = User.objects.get(username=username)
    user_posts=Post.objects.filter(user=user)
    return render(request, "midd19/user_view.html",{"posts":user_posts,"user":user})



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



def post_view(request,username,post_id):
    #post working with
    user_post=Post.objects.get(id=post_id)

    #comments on user_post
    comments=user_post.comment_set.all().order_by("-time")

    form=CommentForm()
    return render(request, "midd19/post_view.html", {"post":user_post,"form":form,"comments":comments})

def comment(request,username):
    if request.method == 'POST':
        form=CommentForm(request.POST)
        print("hi")
        if form.is_valid():
            print("hi")
            content=form.cleaned_data.get("comment")
            anonymous=form.cleaned_data.get("anonymous")
            post_id=form.cleaned_data.get("prime")
            user_post=Post.objects.get(id=int(post_id))

            comment=Comment(comment=content,anonymous=anonymous,post=user_post,user=request.user)
            comment.save()
            user_post.comment_count+=1
            user_post.save()

            response_data = {}
            response_data['result'] = 'Create post successful!'
            response_data['text'] = comment.comment
            response_data['time']=comment.time
            print(comment.anonymous)
            if comment.anonymous:
                response_data['user'] = "Anonymous"
            else:
                response_data['user'] = request.user.username

            return JsonResponse(response_data)

    return JsonResponse({"nothing to see": "this isn't happening"})

def like_dislike(request):
    if request.method == 'POST':
        user_id = request.POST("user_id")
        preference = request.POST("preference")




#
#def post(request):
#    if request.method =="POST":
#        form=PostForm(request.POST)
#        if form.is_valid():
#            title = form.cleaned_data.get("title")
#            content = form.cleaned_data.get('content')
#            anonymous = form.cleaned_data.get('anonymous')
#            username = request.user
#            post = Post(title=title,content=content,anonymous=anonymous,user=request.user)
#            post.save()
#            return HttpResponseRedirect(reverse("chatforum"))
#    else:
#        form = PostForm()
#    return render(request,'midd19/chatforum.html',{'form':form})
