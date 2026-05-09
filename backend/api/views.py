from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Users, Contacts, Tasks, Notifications, Followups
from .serializers import UserSerializer, ContactSerializer, TaskSerializer, NotificationSerializer
from .utils import json_response
from django.db.models import Q
from django.utils import timezone
from django.contrib.auth import authenticate

# AUTH
@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    phone = request.data.get('phone')
    password = request.data.get('password')
    if not phone or not password:
        return json_response(False, "Incomplete data. Phone and password are required.", status=400)
    
    user = authenticate(phone=phone, password=password)
    if user:
        refresh = RefreshToken.for_user(user)
        return json_response(True, "Successful login.", {
            "jwt": str(refresh.access_token),
            "user": UserSerializer(user).data
        })
    else:
        return json_response(False, "Login failed. Invalid credentials.", status=401)

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    data = request.data
    name = data.get('name')
    email = data.get('email', '')
    password = data.get('password')
    phone = data.get('phone')

    if not name or not phone or not password:
        return json_response(False, "Incomplete data. Name, phone, and password are required.", status=400)
    
    if Users.objects.filter(phone=phone).exists():
        return json_response(False, "Phone number is already registered.", status=400)
    
    user = Users.objects.create_user(phone=phone, password=password, name=name, email=email)
    return json_response(True, "User registered successfully.", status=201)


# CONTACTS
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def contacts_read(request):
    search = request.GET.get('search', '')
    query = Contacts.objects.filter(added_by=request.user)
    if search:
        query = query.filter(Q(name__icontains=search) | Q(phone__icontains=search))
    
    serializer = ContactSerializer(query, many=True)
    return json_response(True, "Contacts retrieved successfully.", serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def contacts_create(request):
    data = request.data.copy()
    data['added_by'] = request.user.id
    serializer = ContactSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return json_response(True, "Contact created successfully.", status=201)
    return json_response(False, "Unable to create contact.", serializer.errors, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def contacts_update(request):
    contact_id = request.data.get('id')
    try:
        contact = Contacts.objects.get(id=contact_id, added_by=request.user)
        contact.name = request.data.get('name', contact.name)
        contact.phone = request.data.get('phone', contact.phone)
        contact.email = request.data.get('email', contact.email)
        contact.save()
        return json_response(True, "Contact updated successfully.")
    except Contacts.DoesNotExist:
        return json_response(False, "Contact not found.", status=404)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def contacts_delete(request):
    contact_id = request.data.get('id')
    try:
        contact = Contacts.objects.get(id=contact_id, added_by=request.user)
        contact.delete()
        return json_response(True, "Contact deleted successfully.")
    except Contacts.DoesNotExist:
        return json_response(False, "Contact not found.", status=404)


# TASKS
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tasks_read(request):
    status = request.GET.get('status', '')
    priority = request.GET.get('priority', '')
    search = request.GET.get('search', '')
    assigned_to = request.GET.get('assigned_to', '')

    query = Tasks.objects.filter(deleted_at__isnull=True).order_by('-created_at')

    if status:
        query = query.filter(status=status)
    if priority:
        query = query.filter(priority=priority)
    if search:
        query = query.filter(Q(title__icontains=search) | Q(description__icontains=search))
    if assigned_to:
        query = query.filter(assigned_to_id=assigned_to)

    serializer = TaskSerializer(query[:100], many=True)
    return json_response(True, "Tasks retrieved successfully.", serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def tasks_create(request):
    data = request.data.copy()
    data['created_by'] = request.user.id
    if not data.get('assigned_to'):
        data['assigned_to'] = request.user.id

    serializer = TaskSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return json_response(True, "Task created successfully.", status=201)
    return json_response(False, "Unable to create task.", serializer.errors, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def tasks_update(request):
    task_id = request.data.get('id')
    try:
        task = Tasks.objects.get(id=task_id)

        # Update content if provided
        title = request.data.get('title')
        if title:
            task.title = title

        description = request.data.get('description')
        if description is not None:
            task.description = description

        status = request.data.get('status')
        if status:
            task.status = status

        priority = request.data.get('priority')
        if priority:
            task.priority = priority

        due_date = request.data.get('due_date')
        if due_date:
            task.due_date = due_date

        assigned_to = request.data.get('assigned_to')
        if assigned_to:
            task.assigned_to_id = assigned_to

        comment = request.data.get('comment')
        next_followup_date = request.data.get('next_followup_date')

        if status == 'follow_up' or comment:
            Followups.objects.create(
                task=task,
                note=comment,
                followup_date=next_followup_date if next_followup_date else timezone.now()
            )

        task.save()
        return json_response(True, "Task updated successfully.")
    except Tasks.DoesNotExist:
        return json_response(False, "Task not found.", status=404)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def tasks_delete(request):
    task_id = request.data.get('id')
    try:
        task = Tasks.objects.get(id=task_id)
        task.deleted_at = timezone.now()
        task.save()
        return json_response(True, "Task deleted successfully.")
    except Tasks.DoesNotExist:
        return json_response(False, "Task not found.", status=404)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def users_read(request):
    users = Users.objects.filter(is_active=True).order_by('name')
    serializer = UserSerializer(users, many=True)
    return json_response(True, "Users retrieved successfully.", serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    user_id = request.user.id

    stats = {
        'total_contacts': Contacts.objects.filter(added_by_id=user_id).count(),
        'total_tasks': Tasks.objects.filter(deleted_at__isnull=True).count(),
        'assigned_to_others': Tasks.objects.filter(created_by_id=user_id, deleted_at__isnull=True).exclude(assigned_to_id=user_id).count(),
        'assigned_to_me': Tasks.objects.filter(assigned_to_id=user_id, deleted_at__isnull=True).count(),
        'total_followups': Followups.objects.filter(Q(task__assigned_to_id=user_id) | Q(task__created_by_id=user_id)).count(),
        'pending_tasks': Tasks.objects.filter(Q(assigned_to_id=user_id) | Q(created_by_id=user_id), status='pending', deleted_at__isnull=True).count(),
        'completed_tasks': Tasks.objects.filter(Q(assigned_to_id=user_id) | Q(created_by_id=user_id), status='completed', deleted_at__isnull=True).count(),
    }
    
    recent_tasks = Tasks.objects.filter(Q(assigned_to_id=user_id) | Q(created_by_id=user_id), deleted_at__isnull=True).order_by('-created_at')[:5]
    stats['recent_tasks'] = list(recent_tasks.values('title', 'status', 'created_at'))

    recent_notifications = Notifications.objects.filter(user_id=user_id).order_by('-created_at')[:5]
    stats['recent_notifications'] = list(recent_notifications.values('message', 'created_at'))

    return json_response(True, "Dashboard stats retrieved successfully", stats)


# NOTIFICATIONS
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notifications_read(request):
    notifs = Notifications.objects.filter(user=request.user).order_by('-created_at')
    serializer = NotificationSerializer(notifs, many=True)
    return json_response(True, "Notifications retrieved successfully.", serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def notifications_mark_as_read(request):
    notif_id = request.data.get('id')
    if notif_id:
        Notifications.objects.filter(id=notif_id, user=request.user).update(is_read=1)
    else:
        Notifications.objects.filter(user=request.user).update(is_read=1)
    return json_response(True, "Notifications marked as read.")
