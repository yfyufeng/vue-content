import groupBy from 'lodash/groupBy';
import difference from 'lodash/difference';

// 将数组转化成树结构的数据
// 这个方法有个缺点：无法组装多层数据
export const listToTableTreeData = (
  parentKey = 'pId',
  rowKey = 'id',
  data,
  belongField,
  sortField,
  expanded
) => {
  const groupData = groupBy(JSON.parse(JSON.stringify(data)), parentKey);
  let treeData = [];
  const pIds = data
    .filter(item => item[belongField].includes(item[parentKey]))
    .map(n => n[parentKey]);
  for (const pId of [...new Set(pIds)]) {
    for (const item of groupData[pId] || []) {
      if (groupData[item[rowKey]]) {
        item.children = groupData[item[rowKey]]
          .map(n => {
            n.depth = 1;
            return n;
          })
          .sort((a, b) => a[sortField] - b[sortField]);
        item.child_num = item.children.length;
      }
      item.depth = 0;
      item.expanded = item.open || expanded;
    }
    if (Array.isArray(groupData[pId])) {
      treeData = treeData
        .concat(groupData[pId].filter(item => item.children))
        .sort((a, b) => a[sortField] - b[sortField]);
    }
  }
  return [...new Set(treeData)];
};

export const cloneObj = obj => {
  if (obj !== null && typeof obj === 'object') {
    return JSON.parse(JSON.stringify(obj));
  } else {
    return obj;
  }
};

export const diff = (arr, diffArr, key) => {
  const arrItem = arr.map(item => item[key]);
  const diffArrItem = diffArr.map(item => item[key]);
  const diffItem = difference(arrItem, diffArrItem);
  const groupData = groupBy(arr, key);
  return diffItem.map(item => {
    return groupData[item][0];
  });
};
