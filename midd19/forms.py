from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import Post, Comment


class SignUpForm(UserCreationForm):
    email = forms.EmailField(max_length=254, help_text='Required. Inform a valid email address.')

    class Meta:
        model = User
        fields = ('username', 'email', 'password1', 'password2', )

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['title','content','anonymous']
        widgets = {
            "title":forms.TextInput(attrs={'class':"box","placeholder":"Title","name":"title","id":"title"}),
            "content":forms.Textarea(attrs={'class':"box","placeholder":"Write Here","name":"post","id":"post"}),
            "anonymous":forms.CheckboxInput(attrs={"name":"anonymous","id":"anonymous"})
        }
