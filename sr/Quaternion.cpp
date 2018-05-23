//
//  SoftwareRenderer
//

#include <cmath>
#include "Quaternion.hpp"
#include "MathUtils.hpp"

namespace sr
{
    const Quaternion Quaternion::IDENTITY(0.0F, 0.0F, 0.0F, 1.0F);
    const Quaternion Quaternion::ZERO(0.0F, 0.0F, 0.0F, 0.0F);

    float Quaternion::getNorm()
    {
        float n = x * x + y * y + z * z + w * w;
        if (n == 1.0F) // already normalized
            return 1.0F;

        return sqrtf(n);
    }

    void Quaternion::normalize()
    {
        float n = x * x + y * y + z * z + w * w;
        if (n == 1.0F) // already normalized
            return;

        n = sqrtf(n);
        if (n < EPSILON) // too close to zero
            return;

        n = 1.0F / n;
        x *= n;
        y *= n;
        z *= n;
        w *= n;
    }

    void Quaternion::rotate(float angle, Vector3F axis)
    {
        axis.normalize();

        float cosAngle = cosf(angle / 2.0F);
        float sinAngle = sinf(angle / 2.0F);

        x = axis.v[0] * sinAngle;
        y = axis.v[1] * sinAngle;
        z = axis.v[2] * sinAngle;
        w = cosAngle;
    }

    void Quaternion::getRotation(float& angle, Vector3F& axis)
    {
        angle = 2.0F * acosf(w);
        float s = sqrtf(1.0F - w * w);
        if (s < EPSILON) // too close to zero
        {
            axis.v[0] = x;
            axis.v[1] = y;
            axis.v[2] = z;
        }
        else
        {
            axis.v[0] = x / s;
            axis.v[1] = y / s;
            axis.v[2] = z / s;
        }
    }

    void Quaternion::setEulerAngles(const Vector3F& angles)
    {
        float angle;

        angle = angles.v[0] * 0.5F;
        const float sr = sinf(angle);
        const float cr = cosf(angle);

        angle = angles.v[1] * 0.5F;
        const float sp = sinf(angle);
        const float cp = cosf(angle);

        angle = angles.v[2] * 0.5F;
        const float sy = sinf(angle);
        const float cy = cosf(angle);

        const float cpcy = cp * cy;
        const float spcy = sp * cy;
        const float cpsy = cp * sy;
        const float spsy = sp * sy;

        x = sr * cpcy - cr * spsy;
        y = cr * spcy + sr * cpsy;
        z = cr * cpsy - sr * spcy;
        w = cr * cpcy + sr * spsy;
    }

    Vector3F Quaternion::getEulerAngles() const
    {
        Vector3F result;

        result.v[0] = atan2f(2.0F * (y * z + w * x), w * w - x * x - y * y + z * z);
        result.v[1] = asinf(-2.0F * (x * z - w * y));
        result.v[2] = atan2f(2.0F * (x * y + w * z), w * w + x * x - y * y - z * z);
        return result;
    }

    float Quaternion::getEulerAngleX() const
    {
        return atan2f(2.0F * (y * z + w * x), w * w - x * x - y * y + z * z);
    }

    float Quaternion::getEulerAngleY() const
    {
        return asinf(-2.0F * (x * z - w * y));
    }

    float Quaternion::getEulerAngleZ() const
    {
        return atan2f(2.0F * (x * y + w * z), w * w + x * x - y * y - z * z);
    }
}
