import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  String? _selectedRoomType;
  final List<String> _roomTypes = ['Single', 'Double', 'AC', 'Non-AC'];

  final _formKey = GlobalKey<FormState>();

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<int> _getRoomAvailability(
    String roomType,
    DateTime checkInDate,
  ) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('roomType', isEqualTo: roomType)
            .where('checkInDate', isEqualTo: checkInDate.toIso8601String())
            .get();

    return snapshot.docs.length;
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate() &&
        _checkInDate != null &&
        _checkOutDate != null &&
        _selectedRoomType != null) {
      final int alreadyBooked = await _getRoomAvailability(
        _selectedRoomType!,
        _checkInDate!,
      );

      const int totalRooms = 5;

      if (alreadyBooked >= totalRooms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No rooms available for selected type and date."),
          ),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('bookings').add({
          'guestName': _nameController.text.trim(),
          'guestPhone': _phoneController.text.trim(),
          'checkInDate': _checkInDate!.toIso8601String(),
          'checkOutDate': _checkOutDate!.toIso8601String(),
          'roomType': _selectedRoomType,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Booking submitted successfully")),
        );

        _nameController.clear();
        _phoneController.clear();
        setState(() {
          _checkInDate = null;
          _checkOutDate = null;
          _selectedRoomType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to submit booking: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
    }
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select Date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Your Room"),
        backgroundColor: const Color(0xFF4B0082),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewBookingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B0082), Color(0xFF800000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      "Booking Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Guest Name",
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator:
                          (value) => value!.isEmpty ? "Enter guest name" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: "Guest Phone Number",
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value!.isEmpty ? "Enter phone number" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDate(context, true),
                            child: Text(
                              "Check-In: ${formatDate(_checkInDate)}",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDate(context, false),
                            child: Text(
                              "Check-Out: ${formatDate(_checkOutDate)}",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRoomType,
                      dropdownColor: Colors.deepPurple.shade100,
                      items:
                          _roomTypes.map((room) {
                            return DropdownMenuItem<String>(
                              value: room,
                              child: Text(room),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoomType = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Room Type",
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator:
                          (value) =>
                              value == null ? "Select a room type" : null,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _submitBooking,
                      icon: const Icon(Icons.check),
                      label: const Text("Submit Booking"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ViewBookingsScreen extends StatelessWidget {
  const ViewBookingsScreen({super.key});

  String formatDate(String isoDate) {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(isoDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Bookings"),
        backgroundColor: const Color(0xFF4B0082),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B0082), Color(0xFF8B0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "❌ Error loading bookings",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final bookings = snapshot.data!.docs;

            if (bookings.isEmpty) {
              return const Center(
                child: Text(
                  "No bookings found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final data = bookings[index].data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(10),
                  color: Colors.white.withOpacity(0.9),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      data['guestName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${data['guestPhone']}"),
                        Text("Room Type: ${data['roomType']}"),
                        Text("Check-In: ${formatDate(data['checkInDate'])}"),
                        Text("Check-Out: ${formatDate(data['checkOutDate'])}"),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
