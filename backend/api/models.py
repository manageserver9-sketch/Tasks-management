from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin

class UserManager(BaseUserManager):
    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError('The Phone field must be set')
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'admin')
        return self.create_user(phone, password, **extra_fields)

class Users(AbstractBaseUser, PermissionsMixin):
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True, max_length=255, blank=True, null=True)
    phone = models.CharField(unique=True, max_length=20)
    role = models.CharField(max_length=10, default='user')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(blank=True, null=True)
    fcm_token = models.TextField(blank=True, null=True)


    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = ['name']

    class Meta:
        db_table = 'users'


class Categories(models.Model):
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'categories'

class Contacts(models.Model):
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.CharField(max_length=255, blank=True, null=True)
    category = models.ForeignKey(Categories, models.SET_NULL, blank=True, null=True, db_column='category_id')
    added_by = models.ForeignKey(Users, models.CASCADE, db_column='added_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'contacts'


class Tasks(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    assigned_to = models.ForeignKey(Users, models.SET_NULL, db_column='assigned_to', related_name='assigned_tasks', blank=True, null=True)
    created_by = models.ForeignKey(Users, models.CASCADE, db_column='created_by', related_name='created_tasks')
    group_id = models.IntegerField(blank=True, null=True)
    status = models.CharField(max_length=11, default='pending')
    priority = models.CharField(max_length=6, default='medium')
    due_date = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    deleted_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'tasks'


class Followups(models.Model):
    task = models.ForeignKey(Tasks, models.CASCADE)
    contact = models.ForeignKey(Contacts, models.SET_NULL, blank=True, null=True)
    note = models.TextField(blank=True, null=True)
    followup_date = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'followups'


class Notifications(models.Model):
    user = models.ForeignKey(Users, models.CASCADE)
    message = models.TextField()
    is_read = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
