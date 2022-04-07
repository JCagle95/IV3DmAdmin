from django.db import models
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser, User
from django.utils import timezone
import datetime
import uuid
import json

# Create your models here.
class UserManager(BaseUserManager):
    def create_user(self, username, password):
        if not username:
            raise ValueError("Email must exist")

        user = self.model(username=username)
        user.set_password(password)
        user.save()
        return user

class User(AbstractBaseUser):
    username = models.CharField(max_length=255, unique=True)
    uuid = models.UUIDField(default = uuid.uuid4, editable = False, unique=True)

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = []

    objects = UserManager()

    is_active = models.BooleanField(default=True)
    is_admin = models.BooleanField(default=False)

    def __str__(self):
        return self.username
