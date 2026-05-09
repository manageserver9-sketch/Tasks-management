from rest_framework.response import Response

def json_response(success, message, data=None, status=200):
    return Response({
        "success": success,
        "message": message,
        "data": data
    }, status=status)
