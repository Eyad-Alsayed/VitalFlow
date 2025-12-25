import requests
import json
import sys

def test_api():
    """Simple API test script"""
    base_url = "http://localhost:8000"
    
    print("Testing Medical Booking API Connection...")
    print("=" * 50)
    
    try:
        # Test root endpoint
        print("1. Testing API root...")
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print(f"   ✓ API Root: {response.json()}")
        else:
            print(f"   ✗ API Root failed: {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("   ✗ Cannot connect to API server")
        print("   Make sure the server is running: python simple_main.py")
        return False
    
    try:
        # Test bookings endpoint
        print("\n2. Testing bookings endpoint...")
        response = requests.get(f"{base_url}/bookings/")
        if response.status_code == 200:
            bookings = response.json()
            print(f"   ✓ Bookings endpoint works")
            print(f"   ✓ Found {len(bookings)} booking(s)")
            
            if bookings:
                print("   Sample booking:")
                for key, value in list(bookings[0].items())[:5]:  # Show first 5 fields
                    print(f"     {key}: {value}")
            else:
                print("   (No bookings found - this is normal for a new database)")
        else:
            print(f"   ✗ Bookings endpoint failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ✗ Error testing bookings: {e}")
        return False
    
    try:
        # Test creating a sample booking
        print("\n3. Testing booking creation...")
        sample_booking = {
            "mrn": "TEST123",
            "patient_name": "Test Patient",
            "procedure": "Test Procedure",
            "type_of_booking": "OR",
            "urgency": "E2",
            "status": "pending",
            "consultant": "Dr. Test",
            "requesting_physician": "Dr. Request"
        }
        
        response = requests.post(
            f"{base_url}/bookings/",
            json=sample_booking,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            created_booking = response.json()
            booking_id = created_booking.get('id')
            print(f"   ✓ Successfully created test booking (ID: {booking_id})")
            
            # Clean up - delete the test booking
            if booking_id:
                delete_response = requests.delete(f"{base_url}/bookings/{booking_id}")
                if delete_response.status_code == 200:
                    print(f"   ✓ Successfully cleaned up test booking")
                else:
                    print(f"   ⚠ Test booking created but cleanup failed (ID: {booking_id})")
        else:
            print(f"   ✗ Booking creation failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ✗ Error testing booking creation: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("✓ API Test completed successfully!")
    print("\nYour API is working perfectly!")
    print("- Database connection: ✓")
    print("- Booking creation: ✓") 
    print("- Data retrieval: ✓")
    print("\nAPI Documentation: http://localhost:8000/docs")
    print("API Root: http://localhost:8000/")
    
    return True

if __name__ == "__main__":
    try:
        if test_api():
            sys.exit(0)
        else:
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)