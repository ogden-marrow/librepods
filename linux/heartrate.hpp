// heartrate.hpp
// Heart rate monitoring for AirPods Pro 3 over AACP (RTBuddy / SensorDataWX).
// Protocol notes are taken from the android/rewrite branch of LibrePods.
#ifndef HEARTRATE_HPP
#define HEARTRATE_HPP

#include <QByteArray>
#include <QString>
#include <QList>
#include <optional>

namespace HeartRate
{
    // SensorServiceType values from rtbuddy.proto
    enum Service : quint32
    {
        Heartrate = 19,
        HeartrateV2 = 20,
        HeartrateCommand = 84,
    };

    // AACP message header + BUDDY_COMMAND opcode (0x17)
    static const QByteArray BUDDY_HEADER = QByteArray::fromHex("040004001700");
    static constexpr quint32 DESCRIPTOR_SENSOR_DATA_WX = 0x00100000;

    inline void appendVarint(QByteArray &out, quint64 value)
    {
        while (value >= 0x80)
        {
            out.append(static_cast<char>((value & 0x7F) | 0x80));
            value >>= 7;
        }
        out.append(static_cast<char>(value));
    }

    inline std::optional<quint64> readVarint(const QByteArray &data, int &pos)
    {
        quint64 result = 0;
        int shift = 0;
        while (pos < data.size() && shift < 64)
        {
            quint8 b = static_cast<quint8>(data.at(pos++));
            result |= static_cast<quint64>(b & 0x7F) << shift;
            if (!(b & 0x80))
                return result;
            shift += 7;
        }
        return std::nullopt;
    }

    // Splits a protobuf message into (field number, wire type, value) tuples.
    // Varints are returned in `number`, length-delimited fields in `bytes`.
    struct Field
    {
        quint32 id = 0;
        quint32 wireType = 0;
        quint64 number = 0;
        QByteArray bytes;
    };

    inline QList<Field> parseFields(const QByteArray &data)
    {
        QList<Field> fields;
        int pos = 0;
        while (pos < data.size())
        {
            auto key = readVarint(data, pos);
            if (!key)
                break;
            Field f;
            f.id = static_cast<quint32>(*key >> 3);
            f.wireType = static_cast<quint32>(*key & 7);
            if (f.wireType == 0)
            {
                auto v = readVarint(data, pos);
                if (!v)
                    break;
                f.number = *v;
            }
            else if (f.wireType == 2)
            {
                auto len = readVarint(data, pos);
                if (!len || pos + static_cast<qint64>(*len) > data.size())
                    break;
                f.bytes = data.mid(pos, static_cast<int>(*len));
                pos += static_cast<int>(*len);
            }
            else if (f.wireType == 1)
            {
                pos += 8;
            }
            else if (f.wireType == 5)
            {
                pos += 4;
            }
            else
            {
                break;
            }
            fields.append(f);
        }
        return fields;
    }

    // Builds the packet that sets how often the AirPods report a sensor service.
    // intervalMicros == 0 stops the stream.
    inline QByteArray buildSetReportInterval(quint32 service, quint32 intervalMicros, quint32 seq)
    {
        QByteArray config;
        config.append(char(0x01));
        for (int i = 0; i < 4; ++i)
            config.append(static_cast<char>((intervalMicros >> (8 * i)) & 0xFF));

        // SensorServiceSetting { service = 1; setting = 2; configuration = 3; }
        QByteArray setting;
        setting.append(char(0x08));
        appendVarint(setting, service);
        setting.append(char(0x10));
        setting.append(char(0x02));
        setting.append(char(0x1A));
        appendVarint(setting, config.size());
        setting.append(config);

        // SensorDataWX { seq = 1; service_settings = 8; }
        QByteArray proto;
        if (seq > 0)
        {
            proto.append(char(0x08));
            appendVarint(proto, seq);
        }
        proto.append(char(0x42));
        appendVarint(proto, setting.size());
        proto.append(setting);

        QByteArray packet = BUDDY_HEADER;
        for (int i = 0; i < 4; ++i)
            packet.append(static_cast<char>((DESCRIPTOR_SENSOR_DATA_WX >> (8 * i)) & 0xFF));
        packet.append(static_cast<char>(proto.size() & 0xFF));
        packet.append(static_cast<char>((proto.size() >> 8) & 0xFF));
        packet.append(proto);
        return packet;
    }

    // Returns the SensorDataWX protobuf body if `packet` is an RTBuddy sensor packet.
    inline std::optional<QByteArray> sensorDataBody(const QByteArray &packet)
    {
        if (!packet.startsWith(BUDDY_HEADER) || packet.size() < 12)
            return std::nullopt;
        quint32 descriptor = 0;
        for (int i = 0; i < 4; ++i)
            descriptor |= static_cast<quint32>(static_cast<quint8>(packet.at(6 + i))) << (8 * i);
        if (descriptor != DESCRIPTOR_SENSOR_DATA_WX)
            return std::nullopt;
        int len = static_cast<quint8>(packet.at(10)) | (static_cast<quint8>(packet.at(11)) << 8);
        if (packet.size() < 12 + len)
            return std::nullopt;
        return packet.mid(12, len);
    }

    // Extracts a BPM reading from an incoming packet, if it contains one.
    inline std::optional<int> parseBpm(const QByteArray &packet)
    {
        auto body = sensorDataBody(packet);
        if (!body)
            return std::nullopt;

        for (const Field &f : parseFields(*body))
        {
            if (f.id != 7 || f.wireType != 2) // SensorDataWX.command
                continue;
            quint32 service = 0;
            QByteArray payload;
            for (const Field &c : parseFields(f.bytes))
            {
                if (c.id == 1 && c.wireType == 0)
                    service = static_cast<quint32>(c.number);
                else if (c.id == 3 && c.wireType == 2)
                    payload = c.bytes;
            }
            if ((service == Heartrate || service == HeartrateV2) && payload.size() == 18 &&
                static_cast<quint8>(payload.at(17)) == 0)
            {
                return static_cast<int>(static_cast<quint8>(payload.at(1)));
            }
        }
        return std::nullopt;
    }

    // Firmware 9.x and later uses the *_COMMAND service to start heart rate.
    // `firmware` is the version string from the AirPods metadata (e.g. "9A123").
    inline quint32 serviceForFirmware(const QString &firmware)
    {
        if (!firmware.isEmpty() && firmware.at(0).isDigit() && firmware.at(0).digitValue() >= 9)
            return HeartrateCommand;
        return Heartrate;
    }
}

#endif // HEARTRATE_HPP
