{.push raises: [].}

import
  chronicles, json_serialization, json_serialization/std/options, presto/[route, client]
import
  ../../../waku_store/common,
  ../../../waku_core/message/digest,
  ../serdes,
  ../responses,
  ./types

export types

logScope:
  topics = "waku node rest store_api"

proc decodeBytes*(
    t: typedesc[StoreQueryResponseHex],
    data: openArray[byte],
    contentType: Opt[ContentTypeData],
): RestResult[StoreQueryResponseHex] =
  if MediaType.init($contentType) == MIMETYPE_JSON:
    let decoded = ?decodeFromJsonBytes(StoreQueryResponseHex, data)
    return ok(decoded)

  if MediaType.init($contentType) == MIMETYPE_TEXT:
    var res: string
    if len(data) > 0:
      res = newString(len(data))
      copyMem(addr res[0], unsafeAddr data[0], len(data))

    return ok(
      StoreQueryResponseHex(
        statusCode: uint32(ErrorCode.BAD_RESPONSE),
        statusDesc: res,
        messages: newSeq[WakuMessageKeyValueHex](0),
        paginationCursor: none(string),
      )
    )

  # If everything goes wrong
  return err(cstring("Unsupported contentType " & $contentType))

proc getStoreMessagesV3*(
  # URL-encoded reference to the store-node
  peerAddr: string = "",
  includeData: string = "",
  pubsubTopic: string = "",
  # URL-encoded comma-separated list of content topics
  contentTopics: string = "",
  startTime: string = "",
  endTime: string = "",

  # URL-encoded comma-separated list of message hashes
  hashes: string = "",

  # Optional cursor fields
  cursor: string = "", # base64-encoded hash
  ascending: string = "",
  pageSize: string = "",
): RestResponse[StoreQueryResponseHex] {.
  rest, endpoint: "/store/v3/messages", meth: HttpMethod.MethodGet
.}
