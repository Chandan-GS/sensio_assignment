import asyncio
import logging
import random
import sys
import struct

# pyright: reportMissingImports=false
# pyrefly: ignore [missing-import]
from bless import (
    BlessServer,
    BlessGATTCharacteristic,
    GATTCharacteristicProperties,
    GATTAttributePermissions,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# ── Single service, all 3 characteristics inside it ──────────────────────────
VITALS_SERVICE_UUID    = "0000180D-0000-1000-8000-00805F9B34FB"  # reuse HR service UUID
HEART_RATE_CHAR_UUID   = "00002A37-0000-1000-8000-00805F9B34FB"
SPO2_CHAR_UUID         = "00002A5F-0000-1000-8000-00805F9B34FB"
TEMPERATURE_CHAR_UUID  = "00002A6E-0000-1000-8000-00805F9B34FB"

async def run_simulator():
    logger.info("Initializing BlueNode-Sim BLE Simulator...")

    server = BlessServer(name="BlueNode-Sim")

    def read_request(characteristic: BlessGATTCharacteristic, **kwargs) -> bytearray:
        logger.info(f"--- Read request: {characteristic.uuid} ---")
        return characteristic.value

    def write_request(characteristic: BlessGATTCharacteristic, value: bytearray, **kwargs):
        logger.info(f"--- Write request: {list(value)} ---")
        characteristic.value = value

    server.read_request_func  = read_request
    server.write_request_func = write_request

    char_flags = (
        GATTCharacteristicProperties.read |
        GATTCharacteristicProperties.notify
    )
    char_permissions = GATTAttributePermissions.readable

    # ── All 3 characteristics under ONE service ───────────────────────────────
    await server.add_new_service(VITALS_SERVICE_UUID)
    await server.add_new_characteristic(
        VITALS_SERVICE_UUID, HEART_RATE_CHAR_UUID,
        char_flags, None, char_permissions
    )
    await server.add_new_characteristic(
        VITALS_SERVICE_UUID, SPO2_CHAR_UUID,
        char_flags, None, char_permissions
    )
    await server.add_new_characteristic(
        VITALS_SERVICE_UUID, TEMPERATURE_CHAR_UUID,
        char_flags, None, char_permissions
    )

    logger.info("GATT Server Structure built successfully.")

    await server.start()
    await asyncio.sleep(2)

    logger.info("======================================================")
    logger.info("⚡ BlueNode-Sim is active and broadcasting! ⚡")
    logger.info("Scan and connect via your Flutter application now.")
    logger.info("======================================================")

    base_bpm  = 72.0
    base_spo2 = 98.0
    base_temp = 36.5

    try:
        while True:
            base_bpm  = max(60,   min(120,  base_bpm  + random.choice([-1,   0,   1])))
            base_spo2 = max(94,   min(100,  base_spo2 + random.choice([-0.5, 0,   0.5])))
            base_temp = max(35.0, min(40.0, base_temp + random.choice([-0.1, 0.0, 0.1])))

            bpm_bytes  = bytearray([0x00, int(base_bpm)])
            spo2_bytes = bytearray([int(base_spo2)])
            temp_bytes = bytearray(struct.pack("<H", int(base_temp * 10)))

            server.get_characteristic(HEART_RATE_CHAR_UUID).value  = bpm_bytes
            server.get_characteristic(SPO2_CHAR_UUID).value        = spo2_bytes
            server.get_characteristic(TEMPERATURE_CHAR_UUID).value = temp_bytes

            try:
                server.update_value(VITALS_SERVICE_UUID, HEART_RATE_CHAR_UUID)
                server.update_value(VITALS_SERVICE_UUID, SPO2_CHAR_UUID)
                server.update_value(VITALS_SERVICE_UUID, TEMPERATURE_CHAR_UUID)

                logger.info(
                    f"Broadcasting -> "
                    f"Heart Rate: {int(base_bpm)} BPM | "
                    f"SpO2: {int(base_spo2)}% | "
                    f"Temp: {base_temp:.1f}°C"
                )
            except Exception as update_err:
                logger.debug(f"Notification update loop tick variance: {update_err}")

            await asyncio.sleep(1.0)

    except asyncio.CancelledError:
        logger.info("Advertisement stream cancelled via runtime...")
    finally:
        await server.stop()
        logger.info("GATT server completely cleaned and offline.")


if __name__ == "__main__":
    try:
        asyncio.run(run_simulator())
    except KeyboardInterrupt:
        logger.info("\nSimulator manually terminated via CLI. Exiting safely.")
        sys.exit(0)