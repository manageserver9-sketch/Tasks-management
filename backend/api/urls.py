from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    # Clean URLs

    path('auth/login/', views.login, name='login'),
    path('auth/register/', views.register, name='register'),
    
    path('contacts/read/', views.contacts_read, name='contacts_read'),
    path('contacts/create/', views.contacts_create, name='contacts_create'),
    path('contacts/update/', views.contacts_update, name='contacts_update'),
    path('contacts/delete/', views.contacts_delete, name='contacts_delete'),
    
    path('tasks/read/', views.tasks_read, name='tasks_read'),
    path('tasks/create/', views.tasks_create, name='tasks_create'),
    path('tasks/update/', views.tasks_update, name='tasks_update'),
    path('tasks/delete/', views.tasks_delete, name='tasks_delete'),
    path('tasks/dashboard_stats/', views.dashboard_stats, name='dashboard_stats'),

    path('users/read/', views.users_read, name='users_read'),

    path('notifications/read/', views.notifications_read, name='notifications_read'),
    path('notifications/mark_as_read/', views.notifications_mark_as_read, name='notifications_mark_as_read'),

    # PHP compatibility URLs (for legacy frontend support)
    path('auth/login.php', views.login),
    path('auth/register.php', views.register),
    path('contacts/read.php', views.contacts_read),
    path('contacts/create.php', views.contacts_create),
    path('contacts/update.php', views.contacts_update),
    path('contacts/delete.php', views.contacts_delete),
    path('tasks/read.php', views.tasks_read),
    path('tasks/create.php', views.tasks_create),
    path('tasks/update.php', views.tasks_update),
    path('tasks/delete.php', views.tasks_delete),
    path('tasks/dashboard_stats.php', views.dashboard_stats),
    path('users/read.php', views.users_read),
    path('notifications/read.php', views.notifications_read),
    path('notifications/mark_as_read.php', views.notifications_mark_as_read),

    # Categories
    path('categories/read/', views.categories_read, name='categories_read'),
    path('categories/create/', views.categories_create, name='categories_create'),
    path('categories/update/', views.categories_update, name='categories_update'),
    path('categories/delete/', views.categories_delete, name='categories_delete'),
]

